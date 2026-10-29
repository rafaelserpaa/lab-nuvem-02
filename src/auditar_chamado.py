"""Prática da Aula 11 — consumidor de auditoria: alvo da regra auditoria do barramento manutencao.

O EventBridge entrega o evento inteiro (id, detail-type, source, time, detail...).
A função grava um log JSON por evento no CloudWatch Logs.
"""
import json


def lambda_handler(event, context):
    print(json.dumps({
        "auditoria": True,
        "eventId": event.get("id"),
        "tipo": event.get("detail-type"),
        "origem": event.get("source"),
        "publicadoEm": event.get("time"),
        "chamado": event.get("detail"),
    }, ensure_ascii=False))