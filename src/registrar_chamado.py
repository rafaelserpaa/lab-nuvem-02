"""Prática da Aula 11 — registra um chamado e publica o evento ChamadoRegistrado no EventBridge.

Recebe uma requisição no formato do API Gateway (HTTP API): o corpo chega como texto em event["body"].
Primeiro você a testa pelo console; depois ela passa a ser chamada pela API.
"""
import base64
import datetime
import json
import os
import uuid

import boto3

events = boto3.client("events")
BUS_NAME = os.environ["BUS_NAME"]
CATEGORIAS = {"eletrica", "hidraulica", "climatizacao", "limpeza", "ti"}


def resposta(status, corpo):
    return {"statusCode": status, "headers": {"Content-Type": "application/json"},
            "body": json.dumps(corpo, ensure_ascii=False)}


def validar(ch):
    if not isinstance(ch, dict):
        return ["o corpo precisa ser um objeto JSON"]
    erros = []
    for campo in ("local", "descricao"):
        if not isinstance(ch.get(campo), str) or not ch[campo].strip():
            erros.append(f"'{campo}' é obrigatório")
    if ch.get("categoria") not in CATEGORIAS:
        erros.append(f"'categoria' deve ser uma de: {', '.join(sorted(CATEGORIAS))}")
    if not isinstance(ch.get("urgente"), bool):
        erros.append("'urgente' deve ser booleano (true ou false)")
    return erros


def lambda_handler(event, context):
    corpo = event.get("body") or ""
    if event.get("isBase64Encoded"):
        corpo = base64.b64decode(corpo).decode("utf-8")
    try:
        ch = json.loads(corpo)
    except json.JSONDecodeError:
        return resposta(400, {"erros": ["o corpo não é um JSON válido"]})

    erros = validar(ch)
    if erros:
        return resposta(400, {"erros": erros})

    detalhe = {
        "id": str(uuid.uuid4()),
        "local": ch["local"].strip(),
        "categoria": ch["categoria"],
        "descricao": ch["descricao"].strip(),
        "urgente": ch["urgente"],
        "registradoEm": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
    }
    r = events.put_events(Entries=[{
        "EventBusName": BUS_NAME,
        "Source": "campus.chamados",
        "DetailType": "ChamadoRegistrado",
        "Detail": json.dumps(detalhe, ensure_ascii=False),
    }])
    if r.get("FailedEntryCount", 0) > 0:
        print(json.dumps({"evento": "falha_put_events", "resposta": r["Entries"]}, ensure_ascii=False))
        return resposta(502, {"erro": "não foi possível registrar o evento"})

    print(json.dumps({"evento": "chamado_registrado", "id": detalhe["id"], "urgente": detalhe["urgente"]}))
    return resposta(202, {"id": detalhe["id"], "status": "registrado"})