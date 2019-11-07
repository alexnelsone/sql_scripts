#!/bin/bash

counter=0

for file in `ls *.ddl`;
do
        # first let's get rid of our column scratch file
        rm -f /tmp/col_info.tmp

        table_name=`echo $file | cut -d"." -f 1`
        #printf "working on table $table_name\n"

        printf "working on $file\n"
        sed -i -e 1,5d $file;
        sed -i '$d' $file;
        sed -i '$d' $file;
        sed -i '$d' $file;

# here we need to read in the original ddl file
# and grab the column name and the comment
# we output it to temp file

while IFS= read -r line
do
        first=`echo $line | cut -d"'" -f 1`
        second=`echo $line | cut -d"'" -f 2`


        col_name=`echo $first | cut -d" " -f 1`
        #printf "READING COLUMN_NAME: $col_name\n"

        new_col_name=col${counter}
        printf "replace $new_col_name in $table_name.ddl.hive with $col_name\n"
        sed -i "s/\<${new_col_name}\>/${col_name}/g" $table_name.ddl.hive

        #Now we try to get the comment
        while IFS= read -r line2
        do
                if [[ "$line2"  == *"$col_name"* ]]; then
                        line_without_comma=`echo $line2 | cut -d"," -f 1`

                        if [[ "$line2" == *")"* ]]; then
                                last_line=`echo $line2 | cut -d")" -f 1`
                                new_line="$last_line comment '$second')"
                        else
                                new_line="$line_without_comma comment '$second',"
                        fi

                        sed -i "s/$line2/$new_line/g" $table_name.ddl.hive
                fi
        done < $table_name.ddl.hive

        counter=$(( $counter +1 ))

printf "$col_name '$second'\n" >> /tmp/col_info.tmp

done < $file
#mv $file.hive ./hive-ddl/
#mv $file ./original-ddl/
printf "completed $file\n"
