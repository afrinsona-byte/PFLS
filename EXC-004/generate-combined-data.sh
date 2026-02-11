#!/bin/bash

# 1. SETUP
# Create the output directory and ensure it is empty
mkdir -p COMBINED-DATA
rm -f COMBINED-DATA/*
TRANSLATION="RAW-DATA/sample-translation.txt"

# 2. MAIN LOOP
for lib_dir in RAW-DATA/DNA*; do
    [ -d "$lib_dir" ] || continue
    lib_id=$(basename "$lib_dir")
    
    # Map Library ID (DNA57) to Culture Name (XXX)
    culture=$(grep -w "$lib_id" "$TRANSLATION" | awk '{print $2}')
    [ -z "$culture" ] && continue

    checkm_file="$lib_dir/checkm.txt"
    gtdb_file="$lib_dir/gtdb.gtdbtk.tax"

    # Copy metadata files as requested: XXX-CHECKM.txt and XXX-GTDB-TAX.txt
    cp "$checkm_file" "COMBINED-DATA/${culture}-CHECKM.txt" 2>/dev/null
    cp "$gtdb_file" "COMBINED-DATA/${culture}-GTDB-TAX.txt" 2>/dev/null

    # Reset counters for MAGs and BINs for each culture
    mag_count=1
    bin_count=1

    # 3. PROCESS FASTA FILES
    for fasta in "$lib_dir/bins/"*.fasta; do
        [ -e "$fasta" ] || continue
        filename=$(basename "$fasta")
        
        if [[ "$filename" == "bin-unbinned.fasta" ]]; then
            # (1) Handle bin-unbinned.fasta -> XXX_UNBINNED.fa
            new_id="${culture}_UNBINNED"
            awk -v name="$new_id" 'BEGIN{i=1} /^>/{printf ">%s_%04d\n", name, i++; next} {print}' "$fasta" > "COMBINED-DATA/${new_id}.fa"
        else
            # (2) Handle every other FASTA file
            bin_id="${filename%.fasta}"
            
            # Match the bin name inside the CheckM table and extract stats
            # tr -s ' ' collapses multiple spaces to allow awk to count columns accurately
            stats=$(grep "${bin_id}" "$checkm_file" | tr -s ' ' | head -n 1)
            
            if [[ -n "$stats" ]]; then
                # Columns 13 and 14 are Completeness and Contamination
                comp=$(echo "$stats" | awk '{print $13}')
                cont=$(echo "$stats" | awk '{print $14}')

                # Logic for YYY: MAG if comp >= 50 and cont < 5
                is_mag=$(echo "$comp >= 50 && $cont < 5" | bc -l)
                
                if [[ "$is_mag" -eq 1 ]]; then
                    type="MAG"
                    printf -v zzz "%03d" $mag_count
                    ((mag_count++))
                else
                    type="BIN"
                    printf -v zzz "%03d" $bin_count
                    ((bin_count++))
                fi

                full_name="${culture}_${type}_${zzz}"
                # Reformat deflines (headers) to >XXX_YYY_ZZZ_0001
                awk -v name="$full_name" 'BEGIN{i=1} /^>/{printf ">%s_%04d\n", name, i++; next} {print}' "$fasta" > "COMBINED-DATA/${full_name}.fa"
            fi
        fi
    done
done