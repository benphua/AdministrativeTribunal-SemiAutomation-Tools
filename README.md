# Administrative Tribunals Natural Language Processing (NLP) Semi-Automation Tools to Code Documents for Research

<br>

# Table of Contents

TBC.

<br>

# Description

This repository contains the data and R code (in RMD format) used in an experiment to test the feasibility of using NLP algorithms to reduce the effort (and thus costs) of performing content analysis on Administrative Tribunals. At the moment these tools are focused on document analysis on United Kingdom (UK) Information Rights First-Tier Tribunal Decisions as available on: https://informationrights.decisions.tribunals.gov.uk/Public/search.aspx. 

<br>

## About the Tools

In the publication (TBC, depending on if it gets accepted, regardless we will put it up somewhere), we developed tools based on two types of NLP algorithms: Rule-Based Information Extraction using heuristic patterns inherent in the data and Supervised Machine Learning based Text Soft Classification (i.e. with predicted class and probability of being in that class).

These code are kept in the "Code" folder of this repository.

<br>

### C.1 Information Extraction

In this folder, we provide the R scripts we built to extract seven data variables from each tribunal report. The data variables extractable are as follows:

1. Appeal Outcome: Was the appeal allowed (i.e. in favour of the appellant), or otherwise
2. Appeal Decision date: the date when the decision was made/ promulgated.
3. Government ID for the Appeal: The government unique ID assigned to this case.
4. Appellant name(s): The name(s) of the appellant.
5. Respondent name(s): The name(s) of the respondents.
6. Judge's name: Name of the legal expert on the Tribunal who also chairs the tribunal.
7. Tribunal Lay Members' Name(s), if present: Name(s) of the subject matter experts of the Tribunal, if necessary to the Tribunal. Empty otherwise.

These data variables were chosen for the tools based on our literature review and analysis of their prior usage in historical empirical legal research on tribunals and similar courts.

(Side note: as a weekend project, I am planning to put together an automated dashboard that tracks Judge decision outcomes by Judge preferrably withholding judge name in favour of a unique identifier as a pilot (to protect their privacy). That way we get the facts and can follow-up afterwards without the data being used to cause potentially inaccurate strife.)

<br>

### C.2 Document Retrieval Text Classification

In this folder, we provide the R scripts for the selected supervised machine learning models for four binary soft classifications of tribunal decision reports. The purpose of which is to create ranked, ordered lists of documents based on their probability of falling into a class of research interest to make it easier for empirical researchers to find reports of relevance. The current process for most researchers (especially in regards to tribunals which are not well covered by the likes of LexisNexis or similar companies) is to manually search a database line-by-line (manual linear search) using no filtering or very simple filtering (date, etc.). 

The binary classifications are as follows:

1. The Appeal Outcome: Allowed or Dismissed (Useful when the tribunal does not have the appeal outcome as available metadata about a report, which are many tribunals)
2. The Jurisdicational Topic for the Appeal: Freedom of Information Act or Environment Information Regulation
3. Government Agency's (i.e. the Respondent's) reason for refusing to disclose information: Substantive Refusal or Procedural Refusal.
4. If the case was allowed, was information actually disclosed?: Disclosed or Not Disclosed. 


These models were chosen as optimimised by the grid-search cross validation methodology (Out of 8 traditional algorithms - see publication).

<br>

## About the Data

Details about the raw dataset and experimental datasets (including advice for future tribunal researchers) here: https://github.com/benphua/AdministrativeTribunal-SemiAutomation-Tools/blob/main/Datasets/Dataset%20Readme.md

We would request that future researchers of the UK Information Rights Tribunal draw down on *our* dataset for historical data rather than the official source to minimise outgoing download traffic on a public-funded service.
