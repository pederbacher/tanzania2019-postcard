library("rmarkdown")

render("index.Rmd")
render("images.Rmd")

system("chromium-browser index.html &")
##file.create(".nojekyll")

##
## file.remove(dir("images", full.names=TRUE))
tag <- "tanzania"
minstars <- 5
outdir <- "images"
outwidth <- 1500
##install.packages("RSQLite")
library("RSQLite")
# connect to the sqlite file
con = dbConnect(drv=RSQLite::SQLite(), dbname="~/.local/share/shotwell/data/photo.db")
dbGetInfo(con)
dbListTables(con)
x <- dbGetQuery(con, "SELECT * FROM PhotoTable")
tags <- dbGetQuery(con, "SELECT * FROM TagTable")
## Get the ids of the photos with the tag
tmp <- tags$photo_id_list[tags$name == tag]
ids <- strtoi(gsub("thumb", "", strsplit(tmp, ",")[[1]]), 16)
## Videos are NA
ids <- ids[!is.na(ids)]
## The stars
x <- x[x$id %in% ids & x$rating >= minstars, ]
## Export the photos at ix
x$newtime <- gsub(" ", "_", as.character(ISOdatetime(1970,1,1,0,0,0, tz="GMT") + x$exposure_time + 3600))
x$filenew <- paste0(outdir,"/",x$newtime,"__",basename(x$filename))
## Remove the ones that are not in the new
orfiles <- paste0(outdir,"/",dir(outdir))
sapply(orfiles[!orfiles %in% x$filenew], function(fil){ file.remove(fil) })
## Make the dir
dir.create(outdir, showWarnings=FALSE)
## Dont do it for ones already there
x <- x[which(!x$filenew %in% orfiles), ]
## Then convert
if(nrow(x) > 0){
    for(i in 1:nrow(x)){
        cat("",i)
        ## Must escape paranteses for convert
        nm <- gsub("\\)","\\\\)", gsub("\\(","\\\\(",x$filename[i]))
        nmnew <- gsub("\\)","\\\\)", gsub("\\(","\\\\(",x$filenew[i]))
        ##
        msg <- system(paste0("convert ",nm," -resize ",outwidth," ",nmnew))
        if(msg > 0){
            cat("\n-------- \ni=",i,": A message from convert \n--------\n",sep="")
            ## Some warning, check if the new file is there
        }
        if(!file.exists(x$filenew[i])){
            ## File is not there, try other approach
            cat("\n-------- \nCouldn't convert, so trying cp and mogrify \n",sep="")
            system(paste0("cp ",nm," ",nmnew))
            system(paste0("mogrify -strip ",nmnew))
            system(paste0("mogrify -resize ",outwidth," ",nmnew))
            cat("\n--------\n")
        }
        system(paste0("mogrify -auto-orient ",nmnew))
    }
}


#####################################################################################
## ## READ FROM shotwell DB

## ##install.packages("RSQLite")
## library("RSQLite")
## # connect to the sqlite file
## con = dbConnect(drv=RSQLite::SQLite(), dbname="~/.local/share/shotwell/data/photo.db")
## dbGetInfo(con)
## dbListTables(con)
## x <- dbGetQuery(con, "SELECT * FROM PhotoTable")
## tags <- dbGetQuery(con, "SELECT * FROM TagTable")
## tags$name
## x[x$]

## x$backlinks

## x <- dbGetQuery(con, "SELECT * FROM TagTable")
## str(x)
#####################################################################################


#####################################################################################
## ## Old read all image file info

## system("exiv2 -pt tmp_images/IMG_0917.JPG", intern=TRUE)
## system("file tmp_images/IMG_0917.JPG", intern=TRUE)
## system("convert tmp_images/IMG_0917.JPG json:", intern=TRUE)

## filesnew <- sapply(1:length(files), function(i){
##     print(i)
##     ## Convert filenames to time
##     x <- system(paste0("exiv2 -pt ",folder,"/",files[i]), intern=TRUE)
##     nms <- sapply(strsplit(x, "  "), function(x){ x[1] })
##     x <- lapply(strsplit(x, "  "), function(xx){
##         xx[-1][nchar(xx[-1]) > 0]
##     })
##     names(x) <- gsub(" ", "", nms)
##     ## The rating
##     rating <- x$Exif.Image.Rating[3]
##     ##
##     tim <- as.character(as.POSIXct(x$Exif.Image.DateTim[3], tz="GMT", format="%Y:%m:%d %H:%M:%S"))
##     tim <- gsub(" ","T",tim)
##     ## Keywords
##     xx <- system(paste0("convert ",folder,"/",files[i]," json:"), intern=TRUE)
##     ii <- grep("Keyword", xx)
##     keywords <- gsub(",", ":", gsub("\\],", "", gsub("\"", "", strsplit(xx[ii], "\\[")[[1]][3])))
##     ## Put together
##     paste0(tim, "::", rating, "::", keywords, "::", files[i])
## })
#####################################################################################
