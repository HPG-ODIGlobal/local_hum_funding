# Données mondiales sur le financement de l'aide humanitaire aux intervenants locaux
Ce référentiel contient les données relatives au processus d'analyse et au financement humanitaire qui ont servi de base à l'analyse présentée au chapitre 1 du rapport 2026 de l'ODI HPG intitulé « The state of international humanitarian funding to local and national actors » (L'état du financement humanitaire international destiné aux acteurs locaux et nationaux). Les données désagrégées sur le financement sont accessibles en anglais, en français, en espagnol et en arabe. De même, cette explication est disponible en anglais, français, espagnol et arabe. Ce référentiel contient également les données brutes de tous les graphiques figurant dans ledit rapport, disponibles [ici](https://github.com/niklasrie/local_hum_funding/tree/ce76e9d30eb6cb7918da004cb09231487da8fb93/analyses).

Cet ensemble de données est destiné à servir de ressource ouverte à la communauté des utilisateurs de données et de politiques humanitaires. Nous vous invitons à nous faire part de vos commentaires sur le processus qui a présidé à son élaboration ainsi que sur son contenu.

# Méthodologie d'analyse

Le processus d'analyse a comporté les étapes suivantes :

1.	Collecte de différents ensembles de données sur le financement humanitaire
2.	Nettoyage de ces ensembles de données
3.	Consolider ces ensembles de données en un seul ensemble global et exhaustif sur le financement humanitaire
4.	L’identification des acteurs locaux et nationaux bénéficiaires de ce financement, tout en évitant les doubles comptages

Des liens vers les différentes sources sont inclus [ci-dessous](#sources-de-données). Le nettoyage de chaque ensemble de données a été effectué manuellement lors de la première itération de cette analyse et n'est pas actuellement inclus dans ce référentiel. Les étapes trois et quatre sont expliquées ci-dessous.

## Sources de données

La section « Méthodologie » du rapport 2026 de l'ODI HPG intitulé « The state of international humanitarian funding to local and national actors » fournit, pour chaque source, des précisions sur les étapes manuelles supplémentaires nécessaires pour regrouper ces ensembles de données en un seul jeu de données global.

### Service de surveillance financière

La majorité des données sur le financement humanitaire direct, provenant principalement de donateurs gouvernementaux à destination des acteurs internationaux, nationaux et locaux, repose sur les données historiques de financement du [Service de surveillance financière](https://fts.unocha.org/) du Bureau des Nations Unies pour la coordination des affaires humanitaires.
Les données du Service de surveillance financière incluses dans ce référentiel ne comprennent qu’un nombre limité de colonnes et contiennent déjà des valeurs en dollars américains corrigées de l'inflation (ces valeurs ont été ramenées aux prix constants de 2023). Le script utilisé pour télécharger cet ensemble de données depuis l'API du Service de surveillance financière ainsi que pour convertir les valeurs aux prix de 2023 est disponible dans [le référentiel correspondant au rapport GHA 2025 de l'ALNAP](https://github.com/ALNAP-Comms/gha_2025/tree/main/scripts).

### Fonds de financement commun pour les pays

Les données relatives aux fonds de financement commun pour les pays ont été téléchargées à partir de l'outil [CBPF Data Explorer](https://cbpf.data.unocha.org/dataexplorer.html).

Les données relatives au financement des sous-subventions accordées par les organismes chargés de la mise en œuvre des projets du fonds de financement commun pour les pays à d'autres organisations partenaires ne sont actuellement pas accessibles au public avec une ventilation détaillée au niveau des projets. Le bureau du Fonds de financement commun pour les pays a toutefois partagé ces données avec les auteurs. Elles figurent dans les résultats agrégés de l’analyse disponibles dans le dossier [output](https://github.com/niklasrie/local_hum_funding/tree/main/output), mais ont été exclues du jeu de [données détaillé](https://github.com/niklasrie/local_hum_funding/blob/main/output/master_local_funding_flows.csv) de référence et des [données d’entrée](https://github.com/niklasrie/local_hum_funding/tree/main/input). **Cela signifie qu’il existe actuellement un écart entre les valeurs du jeu de données désagrégé sur les flux de financement locaux et les résultats agrégés figurant dans le dossier de sortie.**

### Fonds des Nations Unies pour l'enfance

Les données sur les partenaires de mise en œuvre du Fonds des Nations Unies pour l’enfance ont été téléchargées depuis son [portail de transparence en ligne](https://open.unicef.org/documents-and-resources?topic_id=&text_id=implementing%20partners).

### HCR

Les données sur les partenaires de mise en œuvre du HCR ont été téléchargées depuis le [portail des partenaires de l’ONU](https://supportcso.unpartnerportal.org/hc/en-us/articles/13420656571671-Collaboration-with-Funded-Partners).

### PAM

Les données relatives aux partenariats du PAM avec les organisations non gouvernementales ont été téléchargées à partir du [site web du PAM](https://www.wfp.org/non-governmental-organizations).

### OIM

Les données de l’OIM proviennent des tableaux de bord Power BI de [la page web dédiée](https://www.iom.int/awarded-contracts-grants-recipients-and-selected-implementing-partners).

### Réseau de la Fédération internationale des sociétés de la Croix-Rouge et du Croissant-Rouge

Les données sur le financement des Sociétés de la Croix-Rouge et du Croissant-Rouge sont basées sur les données de revenus de la [IFRC Network Databank](https://data.ifrc.org/) pour les pays disposant d’un plan de réponse humanitaire interinstitutions.

## Consolidation des ensembles de données sur le financement

La consolidation automatisée des données de financement suit les étapes suivantes pour chaque ensemble de données source :
1.	Mise en correspondance des colonnes de l’ensemble de données source avec la structure de l’ensemble de données de référence
2.	Ajout de colonnes partagées indiquant si les financements sont reçus directement par des acteurs locaux et nationaux ou indirectement par l’intermédiaire d’organismes tels que les Nations Unies, des fonds communs ou des organisations non gouvernementales
3.	Standardisation des noms de pays et des classifications des organisations donatrices et bénéficiaires par type
4.	Si nécessaire, apporter des modifications spécifiques à l'ensemble de données afin de l'aligner sur la structure de l'ensemble de données de référence (par exemple, ajuster les valeurs en dollars américains en fonction de l’inflation
5.	Consolidation de l’ensemble de données source « aligné » dans l’ensemble de données de référence
6.	Si nécessaire, suppression des doubles comptages des financements dans les données préexistantes et nouvellement ajoutées

Il convient de noter que l’élimination des doubles comptages signifie ici qu’un même flux de financement n’est pas comptabilisé deux fois ou plus à partir de différentes sources. Ce même financement peut toutefois apparaître plusieurs fois à différentes étapes de la chaîne de financement (par exemple, une première fois lorsqu’il est versé par un donateur public à une agence des Nations Unies, puis une seconde fois lorsqu’il est transféré par cette agence à une organisation non gouvernementale. Compte tenu de la quantité limitée de données rendues publiques par les intermédiaires, il n'est actuellement pas possible de retracer le parcours des fonds au sein du système humanitaire d'un acteur à l'autre. Les fonds de financement commun pour les pays font exception à cette règle, mais ils ne publient actuellement pas non plus de données sur les sous-subventions accordées dans le cadre de leurs projets [voir ci-dessus](#fonds-des-nations-unies-pour-l'enfance).

## Processus d'analyse

Le [processus de consolidation](#consolidation-des-ensembles-de-données-sur-le-financement) permet d'obtenir un ensemble de données global et détaillé sur les flux de financement humanitaire, ventilés par pays, donateur et organisation bénéficiaire. Cet ensemble de données peut ensuite servir afin d’analyser la part des financements humanitaires internationaux versée aux acteurs locaux et nationaux. Il convient de noter que la disponibilité des données par année varie selon la source, seules les années 2022 à 2024 comprennent des données issues de l’ensemble des sources énumérées ci-dessus.

Le [script d'analyse](https://github.com/niklasrie/local_hum_funding/blob/main/code/2_loc_analysis.R) de ce référentiel effectue quatre analyses différentes :
1.	Les montants des financements humanitaires internationaux reçus par les différents types d'acteurs locaux et nationaux. Ces montants sont obtenus par simple addition, par type et par année.
2.	Le pourcentage des fonds humanitaires internationaux qui parviennent chaque année aux acteurs locaux et nationaux, que ce soit directement ou indirectement. À cette fin, nous estimons le financement humanitaire reçu par les quatre agences des Nations Unies pour lesquelles nous disposons de nos partenaires (OIM, Fonds des Nations Unies pour l'enfance, HCR et PAM) en nous basant sur leurs propres rapports annuels, et non sur les données du Service de surveillance financière. Nous utilisons ensuite comme dénominateur le montant total des financements humanitaires internationaux directs provenant uniquement du Service de surveillance financière avant 2022, puis les données combinées du Service de surveillance financière et de ces quatre agences des Nations Unies pour la période 2022-2024. Nous retirons les données relatives aux sous-subventions des fonds de financement commun pour les pays du numérateur afin de respecter la définition du « Grand Bargain » selon laquelle le financement accordé aux acteurs locaux et nationaux doit être le plus direct possible (c'est-à-dire passer par un seul intermédiaire au maximum).
3.	Le montant et la part des fonds humanitaires internationaux alloués chaque année aux acteurs locaux et nationaux, par pays. Nous utilisons les données du Service de surveillance financière relatives au financement humanitaire total par pays comme dénominateur pour le calcul du pourcentage.
4.	Montants des financements humanitaires internationaux versés aux acteurs locaux et nationaux par donateur. Ces montants sont obtenus par simple addition, par donateur et par année.
