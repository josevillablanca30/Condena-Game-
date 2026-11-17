extends RefCounted
class_name CondenaChapterOneScript

# Transcripcion del Documento Maestro del Proyecto CONDENA,
# "GUION DEFINITIVO COMPLETO — CAPITULO 1: EL POLLO".
# No incluye dialogos no aprobados.
const TITLES := [
    "DIEZ AÑOS", "EL COMEDOR", "PRIMERA PELEA",
    "EL HOMBRE DE LA ESQUINA", "LA SEGUNDA PRUEBA",
    "EL PRECIO DEL RESPETO", "EL QUE MANDA",
    "NO ESTÁS LISTO", "NADIE LO MOLESTA"
]

static func title_for(index: int) -> String:
    if index < 0 or index >= TITLES.size():
        return ""
    return TITLES[index]

static func lines_for(index: int) -> Array[Dictionary]:
    match index:
        0:
            return [
                {"speaker": "PROTAGONISTA", "text": "Antes lo tenía todo: cuentas con accesos irrestrictos, servidores vulnerables a mi antojo, dinero digital que nadie rastreaba. Libertad total tras una pantalla... Ahora nada de esa mierda sirve aquí adentro."},
                {"speaker": "PROTAGONISTA", "text": "Diez años. Diez años tengo que sobrevivir a este infierno."}
            ]
        1:
            return [
                {"speaker": "EL CHICO", "text": "¡Oye, pollo! Lávame la bandeja antes de que te la ponga en la cara. Mírame cuando te hablo, longi.",
                 "choices": [
                    {"id": "comedor", "value": "A", "label": "Ya, tranquilo...", "reply": "Así me gusta, perkin culao."},
                    {"id": "comedor", "value": "B", "label": "Lava tu hueá voh.", "reply": "¡¿Qué dijiste, tonto rehueón?!"},
                    {"id": "comedor", "value": "C", "label": "No responder y sostener la mirada", "reply": "¿Te creí choro, gil colao?"}
                 ]}
            ]
        3:
            return [
                {"speaker": "EL DESCONOCIDO", "text": "Aquí la fuerza no sirve de nada si no sabés cuándo usarla. Todos te van a medir los primeros días. Quieren saber de qué estay hecho."},
                {"speaker": "PROTAGONISTA", "text": "¿Hasta cuándo?"},
                {"speaker": "EL DESCONOCIDO", "text": "Hasta que ya nadie quiera probarte."}
            ]
        4:
            return [
                {"speaker": "EL FLACO", "text": "Oye, informático. Se me ensuciaron las zapatillas con el barro del patio. Límpialas con la polera.",
                 "choices": [
                    {"id": "flaco", "value": "A", "label": "Negarse con firmeza"},
                    {"id": "flaco", "value": "B", "label": "Intentar razonar"},
                    {"id": "flaco", "value": "C", "label": "Aceptar la exigencia"}
                 ]}
            ]
        5:
            return [
                {"speaker": "CONDENA", "text": "Tres presos acorralan a El Joven en los lavaderos.",
                 "choices": [
                    {"id": "joven", "value": "A", "label": "Intervenir y defender a El Joven"},
                    {"id": "joven", "value": "B", "label": "Ignorar y seguir de largo"},
                    {"id": "joven", "value": "C", "label": "Unirse a la intimidación"}
                 ]}
            ]
        6:
            return [
                {"speaker": "EL GUATÓN", "text": "Me han hablado harto de voh, informático. Dicen que tenéis patas para pararte... Vamos a ver si aguantái a un choro de verdad."}
            ]
        8:
            return [
                {"speaker": "PROTAGONISTA", "text": "¿Por qué nadie te molesta a ti?"},
                {"speaker": "EL DESCONOCIDO", "text": "Porque ya me conocen."},
                {"speaker": "PROTAGONISTA", "text": "¿Quién erís voh realmente?"},
                {"speaker": "EL DESCONOCIDO", "text": "Un hueón que quiere terminar de comer tranquilo."},
                {"speaker": "CONDENA", "text": "FIN DEL CAPÍTULO 1\n9 AÑOS, 11 MESES Y 23 DÍAS RESTANTES."}
            ]
    return []
