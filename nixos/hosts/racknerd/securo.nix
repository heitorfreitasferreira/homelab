# Securo 0.20.0, os mesmos containers do chart oficial. Banco no Postgres do host (pgvector).
# Worker com concorrencia 1: no chart eram 2 processos e o uso nao pede mais.
{ config, lib, ... }:
let
  backend = "ghcr.io/securo-finance/securo-backend:0.20.0";
  net = [ "--network=apps" ];
  env = {
    AGENTS_BUILTIN_MCP_URL = "http://securo-mcp:8765/mcp";
    AGENTS_DEFAULT_MODEL = "";
    AGENTS_DEFAULT_PROVIDER = "ollama";
    AGENTS_EMBEDDING_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2";
    AGENTS_EMBEDDING_PROVIDER = "native";
    AGENTS_ENABLED = "true";
    AGENTS_EXTERNAL_MCP_URL = "";
    AGENTS_EXTRA_MCP_SERVERS = "";
    AGENTS_KNOWLEDGE_STORAGE_PATH = "/app/data/agent_knowledge";
    AGENTS_MCP_EXTERNAL_TTL_DAYS = "90";
    AGENTS_OLLAMA_BASE_URL = "http://ollama:11434";
    AGENTS_OPENAI_COMPAT_BASE_URL = "";
    CELERY_BROKER_URL = "redis://securo-redis:6379/0";
    CELERY_RESULT_BACKEND = "redis://securo-redis:6379/0";
    DEBUG = "false";
    ENABLE_BANKING_API_URL = "https://api.enablebanking.com";
    ENABLE_BANKING_OAUTH_REDIRECT_URI = "https://securo.htrlab.duckdns.org/oauth/callback";
    FRONTEND_URL = "https://securo.htrlab.duckdns.org";
    FX_SYNC_MODE = "on_demand";
    LOCAL_AUTH_ENABLED = "true";
    OIDC_ADMIN_ROLES = "";
    OIDC_AUTO_REGISTER = "true";
    OIDC_DISCOVERY_URL = "";
    OIDC_ENABLED = "false";
    OIDC_EXISTING_USER_LINK_MODE = "disabled";
    OIDC_PROVIDER_NAME = "OIDC";
    OIDC_REDIRECT_URI = "";
    OIDC_REQUIRE_VERIFIED_EMAIL = "true";
    OIDC_ROLES_CLAIM = "groups";
    OIDC_SCOPES = "openid email profile";
    OIDC_SYNC_ROLES = "false";
    OIDC_WORKSPACE_ROLE_MAP = "";
    PLUGGY_OAUTH_REDIRECT_URI = "https://securo.htrlab.duckdns.org/oauth/callback";
    PLUGINS_ENABLED = "false";
    PLUGINS_INDEX_URL = "https://plugins.usesecuro.com/v1/index.json";
    REDIS_URL = "redis://securo-redis:6379/0";
    SIMPLEFIN_API_URL = "https://beta-bridge.simplefin.org";
    SIMPLEFIN_ENABLED = "false";
    STORAGE_LOCAL_PATH = "/app/data/attachments";
    STORAGE_PROVIDER = "local";
    STORAGE_S3_ADDRESSING_STYLE = "auto";
    STORAGE_S3_ALLOW_INSECURE_HTTP = "false";
    STORAGE_S3_BUCKET = "";
    STORAGE_S3_ENDPOINT_URL = "";
    STORAGE_S3_REGION = "";
    TESOURO_DIRETO_ENABLED = "true";
  };
  app = cmd: {
    image = backend;
    cmd = cmd;
    environment = env;
    environmentFiles = [ config.sops.templates."securo.env".path ];
    volumes = [ "/srv/securo/attachments:/app/data/attachments" ];
    dependsOn = [ "securo-redis" ];
    extraOptions = net;
  };
in
{
  virtualisation.oci-containers.containers = {
    securo-redis = {
      image = "docker.io/library/redis:8-alpine";
      volumes = [ "/srv/securo/redis:/data" ];
      extraOptions = net;
    };
    securo-backend =
      app [
        "uvicorn"
        "app.main:app"
        "--host"
        "0.0.0.0"
        "--port"
        "8000"
      ]
      // {
        ports = [ "127.0.0.1:8000:8000" ];
      };
    securo-worker = app [
      "celery"
      "-A"
      "app.worker"
      "worker"
      "--loglevel=info"
      "--concurrency=1"
    ];
    securo-mcp =
      app [
        "uvicorn"
        "mcp_server.main:app"
        "--host"
        "0.0.0.0"
        "--port"
        "8765"
      ]
      // {
        ports = [ "127.0.0.1:8765:8765" ];
      };
    securo-frontend = {
      image = "ghcr.io/securo-finance/securo-frontend:0.20.0";
      ports = [ "127.0.0.1:8082:8080" ];
      environment = {
        BACKEND_URL = "http://securo-backend:8000";
        FRONTEND_URL = "https://securo.htrlab.duckdns.org";
      };
      dependsOn = [ "securo-backend" ];
      extraOptions = net;
    };
  };

  systemd.services = lib.genAttrs [ "podman-securo-backend" "podman-securo-worker" "podman-securo-mcp" ] (
    _: {
      after = [ "postgresql-passwords.service" ];
      wants = [ "postgresql-passwords.service" ];
    }
  );

  sops.templates."securo.env".content = ''
    DATABASE_URL=postgresql+asyncpg://securo:${config.sops.placeholder."pg_password_securo"}@10.89.0.1:5432/securo
  '';

  systemd.tmpfiles.rules = [
    "d /srv/securo/attachments 0755 root root -"
    "d /srv/securo/redis 0755 999 999 -"
  ];
}
