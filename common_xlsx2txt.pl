import sys
import os
import openpyxl


workbook=openpyxl.load_workbook(sys.argv[1])
InputFile=sys.argv[1]
print ('\n')
print ('Hey There!')
print ('\n')
print ('Your Input Excel File Name is = %s' %InputFile)
print ('\n')
#OutputFile=InputFile.split('.')[0] + '.txt'
OutputFile=sys.argv[2]
print ('Your Output Tab-Delimited Text File Name is = %s' %OutputFile)
print ('\n')
#print type(workbook)
#print (workbook.get_sheet_names())

sheet1=workbook.get_sheet_names()[0]
#print (sheet1)

worksheet=workbook.get_sheet_by_name(sheet1)
#print worksheet

tarray=[[] for i in range(worksheet.max_row)]

#print worksheet.cell(row=25,column=1).value
#print type(worksheet.max_column)
#print type(worksheet.max_row)

for i in range(worksheet.max_row):
	if worksheet.cell(row=i+1,column=1).value is not None:
		for j in range(worksheet.max_column):
			#print worksheet.cell(row=i+1,column=j+1).value
			tarray[i].append(worksheet.cell(row=i+1,column=j+1).value)

#print tarray

tarray_clean= [x for x in tarray if x != []]
#print tarray_clean
#print tarray[1][2]

numrows = len(tarray_clean)
numcols = len(tarray_clean[0])
#print numrows
#print numcols

text_file = open(OutputFile, "w")

for b in range(numrows):
	for c in range(numcols):
		if tarray_clean[b][c] is None:
			print ('', end='\t', file=text_file)
		else:
			print (tarray_clean[b][c], end='\t', file=text_file)
	print ('', file=text_file)

print ('Its all done!')
print ('\n')
