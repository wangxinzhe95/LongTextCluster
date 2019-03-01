#!/bin/bash

export MAHOUT_LOCAL=T

mahout seqdirectory -i file://$(pwd)/byr/ -o file://$(pwd)/byr-seq/ -c UTF-8 -xm sequential -ow

mahout seq2sparse -i ./byr-seq -o ./byr-vector -ow -wt tfidf -lnorm -nv -a  org.wltea.analyzer.lucene.IKAnalyzer --maxDFPercent 70 --namedVector

mahout split -i ./byr-vector/tfidf-vectors --trainingOutput ./byr-train-vector --testOutput ./byr-test-vector --randomSelectionPct 20 --overwrite --sequenceFiles -xm sequential

mahout trainnb -i ./byr-train-vector -el -o ./model -li ./labelindex -ow -c

mahout testnb -i ./byr-train-vector -m ./model -l ./labelindex -ow -o byr-testing -c

mahout testnb -i ./byr-test-vector -m ./model -l ./labelindex -ow -o ./byr-testing -c
