REGISTER /usr/lib/pig/piggybank.jar;
extract_details = LOAD '/user/cloudera/pig_analisis_opinions/critiquescinematografiques.csv' 
 USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE')  
 AS (text:chararray, label:int, id:int);
tokens = foreach extract_details generate id,label,text, FLATTEN(TOKENIZE(text)) As word;
dictionary = load '/user/cloudera/pig_analisis_opinions/AFINN.txt' 
 using PigStorage('\t') AS(word:chararray,rating:int);
word_rating = join tokens by word left outer, dictionary by word using 'replicated';
describe word_rating;
rating = foreach word_rating 
 generate tokens::id as id,tokens::text as text, tokens::label as label, dictionary::rating as rate;
word_group = group rating by (id,text,label);
avg_rate = foreach word_group generate group, AVG(rating.rate) as AVG;
comparacio = foreach word_group generate group, ((avg_rate.AVG > 0 and label.label==1) or (avg_rate.AVG <= 0 and label.label==0) ? True : False) as comp;
STORE avg_rate INTO '/user/cloudera/WorkspacePigAnalisisOpinionsExercici/resultat_analisis_opinions' 
 USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');
STORE comparacio INTO '/user/cloudera/WorkspacePigAnalisisOpinionsExercici/resultat_analisis_opinions' 
 USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');
