# Datos globales sobre financiación humanitaria para los actores locales
Este repositorio contiene el proceso de análisis y los datos sobre financiación humanitaria que sustentan el análisis del capítulo 1 del informe 2026 del HPG de ODI, titulado ["The state of international humanitarian funding to local and national actors"](https://odi.org/en/publications/the-state-of-international-humanitarian-funding-to-local-and-national-actors/). El conjunto de datos desglosados sobre la financiación está disponible en inglés, francés, español y árabe. Asimismo, esta explicación está disponible en inglés, francés, español y árabe. Además, este repositorio contiene [aquí](https://github.com/HPG-ODIGlobal/local_hum_funding/tree/ce76e9d30eb6cb7918da004cb09231487da8fb93/analyses) los datos sin procesar de todas las cifras de dicho informe.

Este conjunto de datos tiene por objeto servir como recurso abierto para la comunidad de usuarios de datos y políticas humanitarias. Cualquier comentario sobre el proceso y su contenido es bienvenido.

# Metodología de análisis

El proceso de análisis consistió en los siguientes pasos:

1.	Obtener conjuntos de datos inconexos y dispares sobre financiación humanitaria.
2.	Limpiar dichos conjuntos de datos.
3.	Fusionar estos conjuntos de datos en un único conjunto de datos global y exhaustivo sobre financiación humanitaria.
4.	Identificar en ese conjunto de datos la financiación destinada a los actores locales y nacionales, evitando dobles contabilizaciones.

Los enlaces a las distintas fuentes figuran [más abajo](#fuentes-de-datos). En la primera iteración de este análisis se limpió cada conjunto de datos de forma manual y actualmente no se incluyen en este repositorio. A continuación se explican los pasos tres y cuatro.

## Fuentes de datos

La sección de metodología del correspondiente informe 2026 del HPG de ODI, titulado ["The state of international humanitarian funding to local and national actors"](https://odi.org/en/publications/the-state-of-international-humanitarian-funding-to-local-and-national-actors/), incluye más detalles de cada fuente sobre los pasos adicionales y manuales que fueron necesarios para cada conjunto de datos, a fin de poder fusionarlos en un único conjunto de datos global.

### Servicio de Seguimiento Financiero

La mayor parte de los datos sobre financiación humanitaria directa –procedente principalmente de donantes gubernamentales y destinada a actores internacionales, nacionales y locales– se basa en datos históricos de financiación del [Servicio de Seguimiento Financiero](https://fts.unocha.org/) de la Oficina de Coordinación de Asuntos Humanitarios de las Naciones Unidas (OCHA).
Los datos del Servicio de Seguimiento Financiero incluidos en este repositorio solo contienen un número reducido de columnas y ya reflejan valores en dólares estadounidenses ajustados a la inflación (los valores en dólares estadounidenses se han deflactado a precios constantes de 2023). El script que descargó este conjunto de datos de la API del Servicio de Seguimiento Financiero y lo deflactó a precios de 2023 se puede consultar en [el repositorio correspondiente del informe GHA (Global Humanitarian Assistance Report) 2025 de ALNAP](https://github.com/ALNAP-Comms/gha_2025/tree/main/scripts).

### Fondos mancomunados para países concretos

Los datos de financiación sobre las asignaciones procedentes de fondos mancomunados para países concretos (FMPC) se descargaron del [explorador de datos de FMPC](https://cbpf.data.unocha.org/dataexplorer.html).

Actualmente no se dispone de datos públicos sobre la financiación de las subvenciones indirectas concedidas por los ejecutores de proyectos de FMPC a otras organizaciones socias con un desglose detallado a nivel de proyecto. Sin embargo, la oficina de FMPC sí facilitó estos datos a los autores y se incluyen en los resultados del análisis agregado en la carpeta de [salida](https://github.com/HPG-ODIGlobal/local_hum_funding/tree/main/output), aunque se omitieron del [conjunto de datos maestro](https://github.com/HPG-ODIGlobal/local_hum_funding/blob/main/output/master_local_funding_flows_es.csv) detallado y de las [entradas de datos](https://github.com/HPG-ODIGlobal/local_hum_funding/tree/main/input). *Esto significa que actualmente existe una discrepancia al sumar los valores del conjunto de datos maestro desagregado de flujos de financiación local para reproducir algunos de los resultados agregados en la carpeta de salida.*

### Fondo de las Naciones Unidas para la Infancia (UNICEF)

Los datos sobre los socios ejecutores de UNICEF se descargaron de su [portal de transparencia en línea](https://open.unicef.org/documents-and-resources?topic_id=&text_id=implementing%20partners).

### Alto Comisionado de las Naciones Unidas para los Refugiados (ACNUR)

Los datos sobre los socios ejecutores del ACNUR se descargaron del [portal de socios de las Naciones Unidas](https://supportcso.unpartnerportal.org/hc/en-us/articles/13420656571671-Collaboration-with-Funded-Partners).

### Programa Mundial de Alimentos (PMA)

Los datos sobre las alianzas del PMA con las ONG se descargaron del [sitio web del PMA](https://www.wfp.org/non-governmental-organizations).

### Organización Internacional para las Migraciones (OIM)

Los datos de la OIM proceden de los paneles de PowerBI disponibles en la [página web específica](https://www.iom.int/awarded-contracts-grants-recipients-and-selected-implementing-partners).

### Red de la Federación Internacional de Sociedades de la Cruz Roja y de la Media Luna Roja

Los datos sobre la financiación para las Sociedades de la Cruz Roja y de la Media Luna Roja se basan en los datos de ingresos del [Banco de Datos de la Red de la Federación Internacional de Sociedades de la Cruz Roja y de la Media Luna Roja](https://data.ifrc.org/) para los países con planes de respuesta humanitaria interinstitucionales.

## Fusión de conjuntos de datos de financiación

La fusión automatizada de los datos de financiación supone los siguientes pasos para cada conjunto de datos de origen:
1.	Mapear las columnas del conjunto de datos de origen en la estructura del conjunto de datos maestro.
2.	Añadir columnas comunes para indicar si los actores locales y nacionales reciben o no financiación, y si esta es directa (lo que suele significar que procede de donantes gubernamentales o privados) o indirecta (a través de intermediarios, por ejemplo, las Naciones Unidas, fondos mancomunados o las ONG).
3.	Estandarizar los nombres de los países y clasificar las organizaciones donantes y receptoras por tipo.
4.	Si es necesario, aplicar cambios específicos al conjunto de datos para adaptarlo a la estructura del conjunto de datos maestro (por ejemplo, ajustar los valores en dólares estadounidenses en función de la inflación).
5.	Fusionar el conjunto de datos de origen "adaptado" con el conjunto de datos maestro.
6.	En caso necesario, eliminar la doble contabilización de la financiación en los datos de financiación preexistentes y en los recién añadidos.

Obsérvese que, en este contexto, eliminar la doble contabilización significa que el mismo flujo de financiación no se contabiliza dos veces (o más) a partir de fuentes diferentes. Sin embargo, la misma financiación podría incluirse varias veces en diferentes etapas de la cadena de financiación (por ejemplo, primero cuando la proporciona un donante gubernamental a un organismo de las Naciones Unidas y de nuevo cuando ese organismo la proporciona a una ONG). Dada la limitada cantidad de datos que los intermediarios difunden públicamente, actualmente no es posible hacer un seguimiento de la financiación a través del sistema humanitario de un actor a otro. La excepción a esto son los fondos mancomunados para países concretos, aunque actualmente tampoco publican datos de subvenciones dentro de los proyectos de FMPC. [Véase más arriba](#fondos-mancomunados-para-países-concretos).

## Proceso de análisis

El [proceso de fusión](#fusión-de-conjuntos-de-datos-de-financiación) genera un conjunto de datos detallado y global sobre los flujos de financiación humanitaria por país, donante y organización receptora. Este conjunto de datos puede utilizarse entonces para analizar cuánto de la financiación humanitaria internacional llegó a los actores locales y nacionales, según los datos disponibles públicamente. Obsérvese que la disponibilidad de datos por año varía en función de la fuente y solo los años 2022 a 2024 incluyen datos de todas las fuentes mencionadas anteriormente.

El [script de análisis](https://github.com/HPG-ODIGlobal/local_hum_funding/blob/main/code/2_loc_analysis.R) de este repositorio realiza cuatro análisis diferentes:
1.	Los importes de la financiación humanitaria internacional recibidos por los diferentes tipos de actores locales y nacionales. Se trata de una suma directa por cada tipo y año.
2.	El porcentaje de financiación humanitaria internacional que llega a los actores locales y nacionales cada año, directa e indirectamente. Para ello, imputamos la financiación humanitaria recibida por los cuatro organismos de las Naciones Unidas de los que disponemos de datos de los socios (OIM, UNICEF, ACNUR y PMA) según sus propios informes anuales, en lugar de los datos del Servicio de Seguimiento Financiero. Luego usamos como denominador el total de la financiación humanitaria internacional directa del Servicio de Seguimiento Financiero solo antes de 2022, y del Servicio de Seguimiento Financiero y los datos de esas cuatro organismos de las Naciones Unidas para el período 2022 a 2024. Eliminamos del numerador los datos de las subvenciones indirectas de los FMPC para corresponder con la definición del Gran Pacto sobre la financiación a los actores locales y nacionales, que ha de ser lo más directa posible (es decir, a través de un intermediario como máximo).
3.	El monto y la proporción de la financiación humanitaria internacional que llega a los actores locales y nacionales cada año por país. Utilizamos los datos del Servicio de Seguimiento Financiero sobre la financiación humanitaria total por país como denominador para el cálculo del porcentaje.
4.	Los importes de financiación humanitaria internacional proporcionados a los actores locales y nacionales por donante. Se trata de una suma directa por donante y año.
