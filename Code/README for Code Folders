# Introduction

The following folders contain the R and RMD code of the best performing algorithms for extracting data variables from tribunal reports as well as soft classifying documents for searching for more complex data variables (i.e. document retrieval using supervised machine learning).

P.S. .R and .SH files can be opened with any text editor but .RMD files require R Studio. However, each .RMD script has a HTML version attached in the folder that can be opened with any web browser. All experiments were run on the Monash MonARCH Computing Cluster using R ver.3.6.5 on four Mk10 Xeon-Platinum-8260 @ 2.50Ghz cores with 32GB of memory. 

P.P.S. Programs designated “Prototype Tools” are meant for tribunal research only requiring them to know how to input data in the required format and change the name of the output file in R. However, they will require additional work to ensure their human-centred usability and not have not been rigorously tested for all possible exception scenarios.

P.P.P.S. Please also note that the UK Freedom of Information Rights (FOI) Tribunal as stated in the main thesis is known more commonly as the UK Information Rights (IR) Tribunal. We used FOI because IR would have been a confusing acronym as it is closely tied to Information Retrieval in the Natural Language Processing field of study. For all appendix material we refer to it as the UK Information Rights Tribunal as that was how we referred to it before writing the thesis and to change it would require modifications to 40+ scripts/ documents.

# C.1 Information Extraction

(File) C.1.1 System A and B Details.docx
This appendix describes the details behind the logic of System A and B supplementing the details in the main thesis as well as the details in the R program codes for both systems. This document is required reading before System A and B can be used as prototype tools for research.

(File) uk_ir_website_scrapper.R: 
(Unified Prototype Tool - RT.1 System A) This program is the web scraping program as noted in S.3.2.1 of the main thesis and System A as noted in the main thesis combined for ease of practical use. The program scrapes the UK Information Rights Tribunal website HTML code and decision PDF link files to date then extracts MD.1 - 5 metadata (i.e. System A). Note this is a BATCH scrapper, i.e. it resolves the MD.1 to 5 data for all decisions in the website to date. Future iterations could include a feature to resolve only the latest decisions based on the government ID attribute of each report.

(File) uk_pdf_downloader_textconverter.R:
(Prototype Tool - Required for RT.1 System B) This program is required for system B to work. From the uk_ir_webscrapper.R output, it takes the PDF URL links and downloads all PDF files of the Tribunal decision reports into its own folder. It then turns all PDF files (including scanned image files via OCR) into a text string and binds them as a column to the table csv from uk_ir_webscrapper.R. Note that “uk_ir_website_scrapper.R” and “uk_pdf_downloader_textconverter.R” in combination represent the automated component of the data collection effort described in S.3.2.1 of the main thesis.

(File) judge_extractor.R: 
(Prototype Tool - RT.1 System B) Constituting system B for MD.6 as described in the thesis. The information extraction program ready to be pilot tested to extract Judge names.

(File) member_extractor.R: 
(Prototype Tool - RT.1 System B) I Constituting system B for MD.7 as described in the thesis. The information extraction program ready to be pilot tested to extract Tribunal Lay Member names.

(File) ie_pred.csv:
Contains the raw returned MD.1 to 7 predictions from System A and B based on the RT.1 test set.

(File) e6.csv:
Dataset with manually coded Judge names and Tribunal Lay Member names for testing performance with the scripts ‘judge_extractor.R’ and ‘member_extractor.R’.


(File) Judge_dict.csv:
Dictionary of Judge names for use with script ‘judge_extractor.R’.

(File) Lay_dict.csv:
Dictionary of Tribunal Lay Members for use with script ‘member_extractor.R’.

# C.2 Document Retrieval Text Classifi cation/ C2.1 Final Models

(Description) This folder contains the final chosen trained model for each RT.2 task based on grid-search cross validation representing the selected models for the prototype tools. These are ready to be pilot tested by legal researchers and are identified by the task BC.1, BC.2, BC.3 and BC.4. Please run in the same folder at their relevant RDS (data containers) files which contain the training data to be fit and the test data to be evaluated.

(File) BC.1 Final Model.Rmd:
Prototype tool to classify UK Information Rights Tribunal Decision Reports into Case Allowed or Case Dismissed and output an ordered list.


(File) BC.2 Final Model.Rmd:
Prototype tool to classify UK Information Rights Tribunal Decision Reports into FOI or EIR Topic and output an ordered list.


(File) BC.3 Final Model.Rmd:
Prototype tool to classify UK Information Rights Tribunal Decision Reports into Substantive Refusal or Procedural Refusal and output an ordered list.


(File) BC.4 Final Model.Rmd:
Prototype tool to classify UK Information Rights Tribunal Decision Reports into Information Disclosed or Not Disclosed and output an ordered list.
 


