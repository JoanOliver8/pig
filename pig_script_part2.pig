REGISTER /usr/lib/pig/piggybank.jar;
comentaris = LOAD '/user/cloudera/pig_analisis_opinions/critiquescinematografiques.csv' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE')  AS (text:chararray, label:int, id:int);
pelis = LOAD '/user/cloudera/pelicules.csv' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE')  AS (id:int, nom_pelicula:chararray);
comentaris_group = group comentaris by id;

/* Per cada id contam les labels positives i les negatives */
countOpinions = foreach comentaris_group
  {
      l_positives = FILTER comentaris BY label == 1;
      l_negatives = FILTER comentaris BY label == 0;
      l_total = COUNT(l_positives)-COUNT(l_negatives);
      GENERATE group as id, COUNT(comentaris.id) as n_comentaris, COUNT(l_positives) as l_positives, COUNT(l_negatives) as l_negatives, l_total as l_total;
  }

/* Feim un join de les pelicules amb el seu n_opinions, les labels positives i les labels negatives */
pelis_join1 = join pelis by id, countOpinions by id using 'replicated';
pelis_opinions = foreach pelis_join1 generate pelis::id as id, pelis::nom_pelicula as nom_pelicula, countOpinions::n_comentaris as n_opinions, countOpinions::l_positives as l_positives, countOpinions::l_negatives as l_negatives, countOpinions::l_total as l_total;

tokens = foreach comentaris generate id,label,text, FLATTEN(TOKENIZE(text)) As word;
dictionary = load '/user/cloudera/pig_analisis_opinions/AFINN.txt' using PigStorage('\t') AS(word:chararray,rating:int);
word_rating = join tokens by word left outer, dictionary by word using 'replicated';
rating = foreach word_rating generate tokens::id as id,tokens::text as text, tokens::label as label, dictionary::rating as rate;
word_group = group rating by id;
avg_rate = foreach word_group generate group as id, AVG(rating.rate) as AVG;

join_final = join pelis_opinions by id, avg_rate by id using 'replicated';
pelis_final = foreach join_final generate pelis_opinions::id as id, pelis_opinions::nom_pelicula as nom_pelicula, pelis_opinions::n_opinions as n_opinions, pelis_opinions::l_positives as l_positives, pelis_opinions::l_negatives as l_negatives,pelis_opinions::l_total as l_total, avg_rate::AVG as AVG;

STORE pelis_final INTO '/user/cloudera/WorkspacePigAnalisisOpinionsExercici/resultat_analisis_opinions_pelicules' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');
