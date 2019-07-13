newDataHostName = "http://newdata2.nadpco.com/"
#TODO
#پارامترهایی که در ابتدای کار باید گرفته شوند
# Host
# FromDate
# ToDate
# ShowAllDays
# Adjusted
# AdjustmentType
# TimeInterval

#تاریخ ToDate باید برابر با تاریخ امروز ست شود

#نصب کلیه پکیج ها در صورت عدم نصب اولیه
list.of.packages <- c("httr", "jsonlite")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(httr)
library(jsonlite)

#گرفتن لیست شرکت ها
GetMarketCompaniesUrl = paste(newDataHostName,
                              "api/v3/Signal/Signal?SpName=GetMarketCompanies",
                              sep = "")
GetMarketCompaniesResult = GET(GetMarketCompaniesUrl, encode = "json")
GetMarketCompaniesParsed = content(GetMarketCompaniesResult, "text", encoding = "utf-8")
Noavaran.Companies = fromJSON(GetMarketCompaniesParsed, flatten = TRUE)
colnames(Noavaran.Companies) = c('Com_ID',
                                 'Com_BourseSymbol',
                                 'Com_Symbol',
                                 'FirstPublicSupplyDate')

# GetDataForAllSymbolsUrl = paste(newDataHostName,"api/v3/Signal/Signal?SpName=GetDataForAllSymbols", sep = "")
# GetDataForAllSymbolsResult = GET(GetDataForAllSymbolsUrl, encode = "json")
# GetDataForAllSymbolsParsed = content(GetDataForAllSymbolsResult, "text", encoding = "utf-8")
# GetDataForAllSymbolsJsonResult = fromJSON(GetDataForAllSymbolsParsed, flatten = TRUE)

GetDataForAllSymbolsJsonResult = fromJSON(content(GET(paste(newDataHostName,"api/v3/Signal/Signal?SpName=GetDataForAllSymbols", sep = ""), encode = "json", add_headers(accept = "text//csv")), "text", encoding = "utf-8"), flatten = TRUE)
colnames(GetDataForAllSymbolsJsonResult) = c('Com_ID',
                                             'Date',
                                             'JalaliDate',
                                             'Open',
                                             'High',
                                             'Low',
                                             'Close',
                                             'Volume',
                                             'Value')

groupedByComId = split.data.frame(GetDataForAllSymbolsJsonResult, GetDataForAllSymbolsJsonResult$Com_ID)

for (i in 1:length(groupedByComId)) {
  row = groupedByComId[[i]]

  Com_Symbol = Noavaran.Companies[Noavaran.Companies$Com_ID == row$Com_ID[1], ]$Com_Symbol
  dataframeName = paste("Noavaran.Symbols.", Com_Symbol, sep = "")

  row = row[ , !(names(row) %in% c('Com_ID'))]
  row$Date = as.Date(row$Date)
  rownames(row) <- NULL

  assign(dataframeName, row)
}
