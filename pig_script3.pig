REGISTER /usr/lib/pig/piggybank.jar;
extract_details = LOAD '/user/cloudera/pig_analisis_opinions/critiquescinematografiques.csv' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE')  AS (text:chararray, label:int, id:int);
tokens = foreach extract_details generate id,label,text, FLATTEN(TOKENIZE(text)) As word;
dictionary = load '/user/cloudera/pig_analisis_opinions/AFINN.txt' using PigStorage('\t') AS(word:chararray,rating:int);
word_rating = join tokens by word left outer, dictionary by word using 'replicated';
describe word_rating;
rating = foreach word_rating generate tokens::id as id,tokens::text as text, tokens::label as label, dictionary::rating as rate;
word_group = group rating by (id,text,label);
avg_rate = foreach word_group generate group, AVG(rating.rate) as AVG;
comp3 = foreach avg_rate generate group, ((AVG>0)? 1 : 0) as avg_positiu:int, AVG;
/* dump comp3; */
comp4 = foreach avg_rate generate group, ((group.label==0)? 1 : 0) as no_label:int, AVG;
/* dump comp4; */
comp5 = foreach avg_rate generate group, (((AVG>=0) AND (group.label==1)) OR ((AVG<0) AND (group.label==0))? 1 : 0) as c:int, AVG;
/* dump comp5; */
/* STORE comp5 INTO '/user/cloudera/WorkspacePigAnalisisOpinionsExercici/resultat_analisis_opinions' 
 USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE'); */

comp5_group = GROUP comp5 ALL;

records_each = FOREACH comp5_group 
                   {
                      trues = FILTER comp5 BY c == 1;
                      falses = FILTER comp5 BY c == 0;

                    GENERATE group, COUNT(trues) as trues, COUNT(falses) as falses;
                   };
/* STORE records_each INTO '/user/cloudera/WorkspacePigAnalisisOpinionsExercici/resultat_analisis_opinions_count' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE'); */

word_rating_group = GROUP word_rating ALL;

records_word = FOREACH word_rating_group 
                   {
                      word_pos = FILTER word_rating BY dictionary.rating >= 0;
                      word_neg = FILTER word_rating BY dictionary.rating < 0;

                    GENERATE group, COUNT(word_pos) as word_pos, COUNT(word_neg) as word_neg;
                   };
STORE records_word INTO '/user/cloudera/WorkspacePigAnalisisOpinionsExercici/resultat_analisis_opinions_words' USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE');
