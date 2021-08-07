	
cd"C:\Users\ycompaore\Desktop\Redaction thèse Yacou\Après confirmation\Paper 2"
cd data
cd "Final data"

do "Child_mother_5hdss_22042020.do"

do "Child_father_5hdss_22042020.do"

do "Child_mgfather_5hdss_22042020.do"

do "Child_mgmother_5hdss_22042020.do"


do "Child_pgfather_5hdss_22042020.do"

do "Child_pgmother_5hdss_22042020.do"

* Fichiers enfants - tantes - oncles
do "Child_maunts_5hdss_22042020.do"
do "Child_paunts_5hdss_22042020.do"
do "Child_puncles_5hdss_22042020.do"
do "Child_muncles_5hdss_22042020.do"
* 
do "child_mother_father_sahel.do"

do "child_parents_mgmother_sahel.do"

do "child_parents_mgparents_sahel.do"

do "child_parents_mgparents_pgmother_sahel.do"

do "child_parents_mgparents_pgparents_sahel.do"

do "child_parents_mgparents_pgparents_puncles_sahel.do"

do "child_parents_mgparents_pgparents_puncles_paunts_sahel.do"

do "child_parents_mgparents_pgparents_puncles-muncles_sahel.do"

do"child_parents_mgparents_pgparents_puncles-muncles_maunts_sahel.do"

* J'enregistre le fichier créer dans le dossier suivant pour la suite de l'étape
	cd ..
	cd ..
	cd  "data analysis" 
	save "final_dataset_paper_1_bis.dta",replace
 


 


