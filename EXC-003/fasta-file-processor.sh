FASTA=$1
START=$(head -n1 $FASTA | awk '{print substr($1,1,1)}')
num_seq=$(grep '>' $FASTA | wc -l | awk '{print $1}' )
total_len_seq=$(grep -v '>' $FASTA | awk 'BEGIN{total_len_seq=0}{total_len_seq += gsub(/[ATGCU]/, "", $1)} END{print total_len_seq}')
avg_seq_len=$((total_len_seq/num_seq))
len_of_long_seq=$((grep ">" $FASTA) | awk 'BEGIN{FS=";"} {print $6}' | awk 'BEGIN{FS=":"} {print $2}' | sort -n | tail -n1)
len_of_short_seq=$((grep ">" $FASTA) | awk 'BEGIN{FS=";"} {print $6}' | awk 'BEGIN{FS=":"} {print $2}' | sort -n | head -n1)
GC=$(grep -v '>' $FASTA | awk '{gc_count += gsub(/[GgCc]/, "", $1)} END {print gc_count}')
GC_content=$(($GC*100/$total_len_seq))
if [ "$START" == '>' ] ; then
 echo "FASTA File Statistics"
 echo "---------------------"
 echo "Number of sequences: $num_seq"
 echo "Total length of the sequences: $total_len_seq"
 echo "Average sequence length: $avg_seq_len"
 echo "Length of the longest sequence:0"
 echo "Length of the shortest sequence:0"
 echo "GC Content (%): $GC_content"
 else
 echo "Not a FASTA file"
fi