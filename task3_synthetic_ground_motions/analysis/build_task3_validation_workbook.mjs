import fs from "node:fs/promises";
import path from "node:path";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const here = path.dirname(new URL(import.meta.url).pathname.replace(/^\/(.:)/, "$1"));
const resultsDir = path.join(here, "results");
const outputDir = path.join(here, "outputs", "task3_ml_validation_20260919");
const previewDir = path.join(outputDir, "previews");

function parseCsv(text) {
  const lines = text.replace(/^\uFEFF/, "").trim().split(/\r?\n/);
  const parseLine = (line) => {
    const out=[]; let value="", quoted=false;
    for (let i=0;i<line.length;i++) {
      const c=line[i];
      if (c==='"') { if (quoted && line[i+1]==='"') { value+='"'; i++; } else quoted=!quoted; }
      else if (c===',' && !quoted) { out.push(value); value=""; }
      else value+=c;
    }
    out.push(value); return out;
  };
  const headers=parseLine(lines[0]);
  const rows=lines.slice(1).filter(Boolean).map(line => {
    const cells=parseLine(line);
    return cells.map((v,i) => {
      if (v==="") return null;
      if (headers[i]!=="method" && headers[i]!=="comparator" && headers[i]!=="label" &&
          headers[i]!=="partition" && headers[i]!=="feature" && headers[i]!=="response_name") {
        const n=Number(v); if (Number.isFinite(n)) return n;
      }
      return v;
    });
  });
  return {headers,rows};
}

async function csv(name) { return parseCsv(await fs.readFile(path.join(resultsDir,name),"utf8")); }
function colName(n) { let s=""; for(;n>0;n=Math.floor((n-1)/26)) s=String.fromCharCode(65+(n-1)%26)+s; return s; }

const fixed=await csv("model_benchmark_summary.csv");
const repeated=await csv("repeated_split_model_summary.csv");
const paired=await csv("repeated_split_paired_comparison.csv");
const detector=await csv("detector_model_sensitivity.csv");
const detectorSummary=await csv("detector_screening_summary.csv");
const splitMetrics=await csv("repeated_split_metrics.csv");
const fixedOutput=await csv("model_benchmark_per_output.csv");
const screening=await csv("instability_screening_audit.csv");
const spectralDetector=await csv("spectral_detector_model_sensitivity.csv");
const outputSpecific=await csv("output_specific_ridge_test_summary.csv");
const failureMixture=await csv("failure_mixture_test_summary.csv");
const spectralRepeated=await csv("spectral_repeated_split_summary.csv");
const outputSpecificRepeated=await csv("output_specific_repeated_split_summary.csv");
const failureMixtureRepeated=await csv("failure_mixture_repeated_split_summary.csv");

const workbook=Workbook.create();
const summary=workbook.worksheets.add("Summary");
const detectorSheet=workbook.worksheets.add("Detector sensitivity");
const repeatedSheet=workbook.worksheets.add("Repeated splits");
const outputSheet=workbook.worksheets.add("Fixed per output");
const screeningSheet=workbook.worksheets.add("Screening audit");
const notes=workbook.worksheets.add("Methods and sources");
const improved=workbook.worksheets.add("Improved models");

const dark="#17365D", mid="#D9EAF7", pale="#EEF4F8", accent="#C55A11", green="#548235";
const font="Arial";
function title(sheet, text, endCol) {
  sheet.showGridLines=false;
  sheet.getRange(`A2:${endCol}2`).merge();
  sheet.getRange("A2").values=[[text]];
  sheet.getRange("A2").format={font:{name:font,size:15,bold:true,color:"#1F1F1F"}};
  sheet.getRange(`A3:${endCol}3`).format.borders={bottom:{style:"thin",color:dark}};
}
function writeTable(sheet,startRow,startCol,data,headerFill=dark) {
  const all=[data.headers,...data.rows];
  const endRow=startRow+all.length-1, endCol=startCol+data.headers.length-1;
  const range=sheet.getRange(`${colName(startCol)}${startRow}:${colName(endCol)}${endRow}`);
  range.values=all;
  range.format.font={name:font,size:10,color:"#1F1F1F"};
  range.format.verticalAlignment="center";
  const hdr=sheet.getRange(`${colName(startCol)}${startRow}:${colName(endCol)}${startRow}`);
  hdr.format={fill:headerFill,font:{name:font,size:10,bold:true,color:"#FFFFFF"},horizontalAlignment:"center",verticalAlignment:"center",wrapText:true,borders:{preset:"inside",style:"thin",color:"#FFFFFF"}};
  if (data.rows.length) sheet.getRange(`${colName(startCol)}${startRow+1}:${colName(endCol)}${endRow}`).format.borders={preset:"inside",style:"thin",color:"#E6E6E6"};
  return {endRow,endCol};
}
function formatMetrics(sheet,startRow,endRow,startCol,headers) {
  headers.forEach((h,i)=>{
    const c=startCol+i;
    if (/R2|nRMSE|nMAE|a10|delta|error|change|lead_time/.test(h)) sheet.getRange(`${colName(c)}${startRow}:${colName(c)}${endRow}`).format.numberFormat="0.000";
    if (/seconds/.test(h)) sheet.getRange(`${colName(c)}${startRow}:${colName(c)}${endRow}`).format.numberFormat="0.00";
  });
}

title(summary,"Task 3 ML validation", "L");
summary.getRange("A5:H5").merge(); summary.getRange("A5").values=[["Fixed 105/45 held-out split"]];
summary.getRange("A5").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
let t=writeTable(summary,6,1,fixed); formatMetrics(summary,7,t.endRow,1,fixed.headers);
summary.getRange("A14:J14").merge(); summary.getRange("A14").values=[["Ten stratified 105/45 held-out splits"]];
summary.getRange("A14").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(summary,15,1,repeated); formatMetrics(summary,16,t.endRow,1,repeated.headers);
summary.getRange("A23:G23").merge(); summary.getRange("A23").values=[["Paired comparison with FMRVR"]];
summary.getRange("A23").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(summary,24,1,paired); formatMetrics(summary,25,t.endRow,1,paired.headers);
summary.getRange("J5:L5").merge(); summary.getRange("J5").values=[["Validated findings"]];
summary.getRange("J5").format={fill:accent,font:{name:font,size:11,bold:true,color:"#FFFFFF"}};
summary.getRange("J6:L11").merge(); summary.getRange("J6").values=[["The failure-gated spectral model reached mean R² 0.722 on the fixed held-out split.\n\nNested repeated validation averaged R² 0.660 (range 0.567–0.708).\n\nA global R² above 0.7 is supported for the fixed split, but not across arbitrary resampling of 150 cases."]];
summary.getRange("J6:L11").format={fill:pale,font:{name:font,size:10,color:"#1F1F1F"},wrapText:true,verticalAlignment:"top"};
summary.freezePanes.freezeRows(3); summary.tabColor=dark;

title(detectorSheet,"Failure-onset threshold sensitivity", "H");
detectorSheet.getRange("A5:G5").merge(); detectorSheet.getRange("A5").values=[["Held-out model metrics"]]; detectorSheet.getRange("A5").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(detectorSheet,6,1,detector); formatMetrics(detectorSheet,7,t.endRow,1,detector.headers);
detectorSheet.getRange("A24:G24").merge(); detectorSheet.getRange("A24").values=[["Screening summary"]]; detectorSheet.getRange("A24").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(detectorSheet,25,1,detectorSummary); formatMetrics(detectorSheet,26,t.endRow,1,detectorSummary.headers);
detectorSheet.freezePanes.freezeRows(6); detectorSheet.tabColor="#5B9BD5";

title(repeatedSheet,"Repeated split metrics", "H");
t=writeTable(repeatedSheet,5,1,splitMetrics); formatMetrics(repeatedSheet,6,t.endRow,1,splitMetrics.headers);
repeatedSheet.freezePanes.freezeRows(5);

title(outputSheet,"Fixed split metrics for all outputs", "H");
t=writeTable(outputSheet,5,1,fixedOutput); formatMetrics(outputSheet,6,t.endRow,1,fixedOutput.headers);
outputSheet.freezePanes.freezeRows(5);

title(screeningSheet,"Instability screening audit", "F");
t=writeTable(screeningSheet,5,1,screening); formatMetrics(screeningSheet,6,t.endRow,1,screening.headers);
screeningSheet.freezePanes.freezeRows(5);

title(notes,"Methods and sources", "H");
notes.getRange("A5:B13").values=[
  ["Item","Definition"],
  ["Raw histories","Signed FLAC2D response histories; no positivity or monotonicity assumption."],
  ["Envelope targets","Displacement and strain use max absolute magnitude. Stress and pore pressure use max absolute change from the initial value."],
  ["Failure cutoff","Earliest runaway crossing among affected nonconstant outputs in a realization; repeated sentinel tail is excluded from ML targets."],
  ["Baseline threshold","10× the largest magnitude observed for that output among histories without a sentinel."],
  ["Repeated validation","10 deterministic stratified splits; each has 105 development and 45 held-out realizations with 34/14 screened records."],
  ["Leakage control","Scaling is fitted on development data only for every split."],
  ["Source","CSV outputs in analysis/results generated by the Task 3 MATLAB validation scripts."],
  ["Original data","Raw MAT files and supplied code remain unchanged."]
];
notes.getRange("A5:B5").format={fill:dark,font:{name:font,size:10,bold:true,color:"#FFFFFF"},horizontalAlignment:"center"};
notes.getRange("A6:B13").format={font:{name:font,size:10,color:"#1F1F1F"},wrapText:true,verticalAlignment:"top",borders:{preset:"inside",style:"thin",color:"#E6E6E6"}};
notes.getRange("A6:A13").format.font={name:font,size:10,bold:true,color:dark}; notes.tabColor="#A5A5A5";

title(improved,"Improved model results", "J");
const fixedProgress={headers:["Model","Threshold","Mean R2","Median R2","Mean nRMSE","Mean nMAE","Mean a10"],rows:[
  ["FMRVR baseline",10,0.439658595478817,0.4562680219572,0.18139851560086,0.117927969845816,0.178441127694859],
  ["Linear ridge",10,0.66471189347802,0.737680870907103,0.136899884788697,0.093238989713253,0.240796019900498],
  ["Transformed-input ridge",10,0.673369160971764,0.723732445726875,0.135925515643958,0.0913724983947009,0.253067993366501],
  ["Spectral ridge",10,0.695877048383995,0.764467034731403,0.130286278834108,0.0848832529200944,0.275621890547264],
  ["Spectral ridge",5,0.718523000289051,0.778564342430552,0.121455148935909,0.0779935865012681,0.294527363184079],
  ["Output-specific ridge",5,...outputSpecific.rows[0].slice(0,5)],
  ["Failure-gated spectral",5,...failureMixture.rows[0].slice(1,6)],
]};
improved.getRange("A5:G5").merge(); improved.getRange("A5").values=[["Fixed 45-case held-out results"]]; improved.getRange("A5").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(improved,6,1,fixedProgress); formatMetrics(improved,7,t.endRow,1,fixedProgress.headers);
const robust={headers:["Model","Mean R2","SD R2","Lower R2","Upper R2","Mean nRMSE","Mean nMAE","Mean a10"],rows:[
  ["FMRVR",repeated.rows[0][1],repeated.rows[0][2],repeated.rows[0][3],repeated.rows[0][4],repeated.rows[0][6],repeated.rows[0][7],repeated.rows[0][8]],
  ["Random forest",repeated.rows[4][1],repeated.rows[4][2],repeated.rows[4][3],repeated.rows[4][4],repeated.rows[4][6],repeated.rows[4][7],repeated.rows[4][8]],
  ["Spectral ridge, 5x",spectralRepeated.rows[0][0],spectralRepeated.rows[0][1],spectralRepeated.rows[0][2],spectralRepeated.rows[0][3],spectralRepeated.rows[0][5],spectralRepeated.rows[0][6],spectralRepeated.rows[0][7]],
  ["Output-specific ridge, 5x",outputSpecificRepeated.rows[0][0],outputSpecificRepeated.rows[0][1],outputSpecificRepeated.rows[0][2],outputSpecificRepeated.rows[0][3],outputSpecificRepeated.rows[0][5],outputSpecificRepeated.rows[0][6],outputSpecificRepeated.rows[0][7]],
  ["Failure-gated spectral, 5x",failureMixtureRepeated.rows[0][0],failureMixtureRepeated.rows[0][1],failureMixtureRepeated.rows[0][2],failureMixtureRepeated.rows[0][3],failureMixtureRepeated.rows[0][5],failureMixtureRepeated.rows[0][6],failureMixtureRepeated.rows[0][7]],
]};
improved.getRange("A17:H17").merge(); improved.getRange("A17").values=[["Ten nested or repeated stratified splits"]]; improved.getRange("A17").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(improved,18,1,robust); formatMetrics(improved,19,t.endRow,1,robust.headers);
improved.getRange("A26:I26").merge(); improved.getRange("A26").values=[["Spectral detector sensitivity"]]; improved.getRange("A26").format={fill:mid,font:{name:font,size:11,bold:true,color:dark}};
t=writeTable(improved,27,1,spectralDetector); formatMetrics(improved,28,t.endRow,1,spectralDetector.headers);
improved.getRange(`H28:I${t.endRow}`).format.numberFormat="0";
improved.freezePanes.freezeRows(3); improved.tabColor=green;

for (const sheet of [summary,detectorSheet,repeatedSheet,outputSheet,screeningSheet,notes,improved]) {
  const used=sheet.getUsedRange(); used.format.autofitColumns(); used.format.autofitRows();
  // Keep prose and wide metric headers readable without oversized columns.
  for (let c=0;c<Math.min(used.columnCount,12);c++) {
    const col=sheet.getRangeByIndexes(0,c,Math.max(used.rowCount,1),1);
    if (col.format.columnWidthPx>190) col.format.columnWidthPx=190;
  }
}
summary.getRange("J:L").format.columnWidthPx=150;
summary.getRange("A:A").format.columnWidthPx=210;
summary.getRange("B:I").format.columnWidthPx=125;
summary.getRange("J:J").format.columnWidthPx=155;
summary.getRange("15:15").format.rowHeightPx=38;
summary.getRange("24:24").format.rowHeightPx=38;
notes.getRange("A:A").format.columnWidthPx=150; notes.getRange("B:B").format.columnWidthPx=520;
notes.getRange("6:13").format.rowHeightPx=38;

workbook.recalculate();
await fs.mkdir(previewDir,{recursive:true});
const renderSpecs=[
  ["Summary","A1:L30"],["Detector sensitivity","A1:H30"],["Repeated splits","A1:H20"],
  ["Fixed per output","A1:H20"],["Screening audit","A1:F20"],["Methods and sources","A1:H15"],
  ["Improved models","A1:J38"]
];
for (const [sheetName,range] of renderSpecs) {
  const blob=await workbook.render({sheetName,range,scale:1.2,format:"png"});
  await fs.writeFile(path.join(previewDir,`${sheetName.replaceAll(" ","_")}.png`),new Uint8Array(await blob.arrayBuffer()));
}

const inspect=await workbook.inspect({kind:"table",range:"Summary!A1:L30",include:"values,formulas",tableMaxRows:30,tableMaxCols:12,maxChars:10000});
await fs.writeFile(path.join(outputDir,"summary_inspect.ndjson"),inspect.ndjson,"utf8");
const errors=await workbook.inspect({kind:"match",searchTerm:"#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",options:{useRegex:true,maxResults:300},summary:"final formula error scan"});
await fs.writeFile(path.join(outputDir,"formula_error_scan.ndjson"),errors.ndjson,"utf8");

const out=await SpreadsheetFile.exportXlsx(workbook);
await out.save(path.join(outputDir,"task3_ml_validation.xlsx"));
console.log(path.join(outputDir,"task3_ml_validation.xlsx"));
