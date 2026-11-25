import importlib.machinery
import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "vagas-buscar"
loader = importlib.machinery.SourceFileLoader("vagas_buscar", str(SCRIPT))
spec = importlib.util.spec_from_loader("vagas_buscar", loader)
vagas = importlib.util.module_from_spec(spec)
loader.exec_module(vagas)


class WhatsappJobTest(unittest.TestCase):
    def test_post_de_vaga(self):
        message = {
            "body": "Vaga: SRE Senior\nEmpresa: Acme\nLocal: Remoto (Brasil)\nhttps://acme.example/vagas/123",
            "timestamp": "1764000000",
        }
        job = vagas.whatsapp_job(message, "Dominando Cloud", [])
        self.assertIsNotNone(job)
        self.assertIn("SRE", job["title"])
        self.assertEqual(job["url"], "https://acme.example/vagas/123")
        self.assertIn("Remoto", job["location"])

    def test_conversa_nao_e_vaga(self):
        message = {
            "body": "Bom dia, pessoal. Alguem sabe de um curso bom de Kubernetes?",
            "timestamp": "1764000000",
        }
        self.assertIsNone(vagas.whatsapp_job(message, "Dominando Cloud", []))

    def test_vaga_sem_link_nao_conta(self):
        message = {
            "body": "Vaga: SRE Senior\nEmpresa: Acme\nLocal: Remoto",
            "timestamp": "1764000000",
        }
        self.assertIsNone(vagas.whatsapp_job(message, "Dominando Cloud", []))


if __name__ == "__main__":
    unittest.main()
