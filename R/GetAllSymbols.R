hostname <- "http://client2.nadpco.com/"
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
GetMarketCompaniesUrl = paste(hostname, "NadpcoClient/GetMarketCompanies", sep = "")
GetMarketCompaniesResult <- GET(GetMarketCompaniesUrl, encode = "json")
GetMarketCompaniesParsed = content(GetMarketCompaniesResult, "parsed", encoding = "utf-8")
Noavaran.Companies <- fromJSON(GetMarketCompaniesParsed, flatten = TRUE)
#View(Noavaran.Companies)

#خواندن پارامترهای لازم از رجیستری
fr <- readRegistry("Software\\Wow6432Node\\NoavaranAmin\\NadpcoClient" , hive = c("HLM", "HCR", "HCU", "HU", "HCC", "HPD"),
                   maxdepth = 10, view = c("default", "32-bit", "64-bit"))

#گرفتن توکن
parameters <- list(
  SerialNumber = fr[1][[1]],
  Ticket = fr[2][[1]]
)

CreateMemberToken2Url = paste(hostname, "NadpcoClient/CreateMemberToken2", sep = "")
CreateMemberToken2result <- POST(CreateMemberToken2Url,body = parameters, encode = "json")
#CreateMemberToken2result

CreateMemberToken2parsed = content(CreateMemberToken2result, "text", encoding = "utf-8")

CreateMemberToken2jsonresult <- fromJSON(CreateMemberToken2parsed, flatten = TRUE)

MemberToken = CreateMemberToken2jsonresult[["MemberToken"]]
tok = MemberToken[["MemT_ProtectedTicket"]]
#tok

auth_token = paste("token:",tok, sep= "")

parameters <- list()
today <- format(Sys.Date(), "%Y/%m/%d")
for(i in 1:nrow(Noavaran.Companies)) {
  row <- Noavaran.Companies[i,]
  parameters[[length(parameters)+1]] <- list(ComIds = row$Com_ID,FromDate = "2000/12/01",ToDate = today,ShowAllDays = F,Adjusted = F,AdjustmentType = 1,TimeInterval = "d")
}

GetNadpcoClientDifferentialDataForAllSymbolsUrl = paste(hostname, "NadpcoClient/GetNadpcoClientDifferentialDataForAllSymbols", sep = "")
GetNadpcoClientDifferentialDataForAllSymbolsResult <- POST(GetNadpcoClientDifferentialDataForAllSymbolsUrl,add_headers(auth_token = auth_token), body = parameters, encode = "json")
#GetNadpcoClientDifferentialDataForAllSymbolsResult

GetNadpcoClientDifferentialDataForAllSymbolsParsed = content(GetNadpcoClientDifferentialDataForAllSymbolsResult, "text", encoding = "utf-8")

GetNadpcoClientDifferentialDataForAllSymbolsJsonResult <- fromJSON(GetNadpcoClientDifferentialDataForAllSymbolsParsed, flatten = TRUE)
colnames(GetNadpcoClientDifferentialDataForAllSymbolsJsonResult)[1] <- "Com_ID"

merged <- merge(x = Noavaran.Companies, y = GetNadpcoClientDifferentialDataForAllSymbolsJsonResult, by = "Com_ID", all = TRUE)
#View(merged)

#تبدیل به دیتافریم های مختلف
symbolVector <- NULL

for(i in 1:nrow(merged)) {
  row <- merged[i,]
  #print(row$Com_Symbol)
  #print(row[,"NadpcoClientDataViews"])
  #print(is.na(row[,"NadpcoClientDataViews"]))

  if (!is.na(row[,"NadpcoClientDataViews"])) {
    dataframeName <- paste("Noavaran.Symbols.", row$Com_Symbol, sep = "")

    Date <-    as.Date(row[,"NadpcoClientDataViews"][[1]]['PKDate'][1,1][[1]])
    Open <-    row[,'NadpcoClientDataViews'][[1]]['ComC_PriceFirst'][1,1][[1]]
    High <-    row[,'NadpcoClientDataViews'][[1]]['ComC_PriceMax'][1,1][[1]]
    Low <-     row[,'NadpcoClientDataViews'][[1]]['ComC_PriceMin'][1,1][[1]]
    Close <-   row[,'NadpcoClientDataViews'][[1]]['ComC_PriceLast'][1,1][[1]]
    Volume <-  row[,'NadpcoClientDataViews'][[1]]['ComC_Volume'][1,1][[1]]

    df <- cbind.data.frame(Date, Open, High, Low, Close, Volume)

    assign(dataframeName, df)

    symbolVector <- c(symbolVector, dataframeName)
  } else {
    print(row$Com_Symbol)
  }
}

#ذخیره در فایل
#dump(symbolVector, "Symbols.txt")
