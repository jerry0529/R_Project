library(glm2)
library(MASS)
library(scatterplot3d)
library(xtable)
library(stepp)
library(stepwise)
library(reshape2)
library(ggplot2)
library(mosaic)
library(mda)
library(mdatools)
library(earth)
library(polspline)
library(faraway)
library(Rmisc)
#-----------------------------------------------------------------------------------------
#Refference from : http://www.dataapple.net/?p=84
#Ū�ɮ�
rfm_data <- read.csv("E:\\Desk\\SPSS\\SPSS\\SPSS_Date\\csv\\RFM�d��-�Ȥ���-1988��.csv")
#����Y
names <- c("ID","Gender","LastTranDate","TranS","TotalAmount")
names(rfm_data) <- names
#��Date�����A
head(rfm_data)
dim(rfm_data)
#uid <- rfm_data[!duplicated(rfm_data[,"ID"]),]
#dim(uid)

#�w�q��ơA�ϥ�"�Ȥ���"
getDataFrame <- function(rfm_data,tIDColName="ID",tDateColName="LastTranDate",tTimesColName="TranS",tAmountColName="TotalAmount"){

  #��������ID�A�óХ߷s���
  new_rfm_data <- rfm_data[!duplicated(rfm_data[,tIDColName]),]
  #�p��̫�@������Z��"����"�@�h�֤�
  Recency<-as.numeric(new_rfm_data[,tDateColName])
  #�b�s��Ʒs�W���e
  new_rfm_data <-cbind(new_rfm_data,Recency)
  
  #�NID���W�Ƨ�
  new_rfm_data <- new_rfm_data[order(new_rfm_data[,tIDColName]),]
  #���������ơA���s�R�W�üg�J�s���
  fr<- as.data.frame(rfm_data[,tTimesColName])
  Frequency<-fr[,1]
  new_rfm_data <- cbind(new_rfm_data,Frequency)
  
  #�p�⥭�����O���B�A���s�R�W�üg�J�s���
  m <- as.data.frame(rfm_data[,tAmountColName])
  Monetary <- m[,1]/Frequency
  new_rfm_data <- cbind(new_rfm_data,Monetary)
  
  return(new_rfm_data)
  
}

#�]�w�nŪ�����ɮ�
rfm_data <- getDataFrame(rfm_data)

#�]�wRFM������
getIndependentScore <- function(rfm_data,r=5,f=5,m=5) {
  
  if (r<=0 || f<=0 || m<=0) return
  
  #��RFM������order�AR�Ѥp��j(R�n�U�p�U�n�AF�令�t��(F�U�j�U�n)�AM�令�t��(M�U�j�U�n)
  rfm_data <- rfm_data[order(rfm_data$Recency,-rfm_data$Frequency,-rfm_data$Monetary),]
  #�p��R�����ơAscoring�O�۩w���
  R_Score <- scoring(rfm_data,"Recency",r)
  #�NR_Score�g�J���
  rfm_data <- cbind(rfm_data, R_Score)
  #��FRM������order�AF�令�t��(F�U�j�U�n)�AR�Ѥp��j(R�n�U�p�U�n�AM�令�t��(M�U�j�U�n)
  rfm_data <- rfm_data[order(-rfm_data$Frequency,rfm_data$Recency,-rfm_data$Monetary),]
  #�p��F������
  F_Score <- scoring(rfm_data,"Frequency",f)
  #�NF_Score�g�J���
  rfm_data <- cbind(rfm_data, F_Score)
  #��MRF������order�AM�令�t��(M�U�j�U�n)�AR�Ѥp��j(R�n�U�p�U�n�AF�令�t��(F�U�j�U�n)
  rfm_data <- rfm_data[order(-rfm_data$Monetary,rfm_data$Recency,-rfm_data$Frequency),]
  #�p��M������
  M_Score <- scoring(rfm_data,"Monetary",m)
  #�NM_Score�g�J���
  rfm_data <- cbind(rfm_data, M_Score)
  
  #��RFM������order�A�Ѥp��j�Ƨ�
  rfm_data <- rfm_data[order(-rfm_data$R_Score,-rfm_data$F_Score,-rfm_data$M_Score),]
  
  #�p������`�M�A�üg�J���
  Total_Score <- c(100*rfm_data$R_Score + 10*rfm_data$F_Score+rfm_data$M_Score)
  rfm_data <- cbind(rfm_data,Total_Score)
  
  return (rfm_data)
  
}

#�]�w���լq�I
scoring <- function (rfm_data,column,r=5){
  
  #�p���l��ƪ���
  len <- dim(rfm_data)[1]
  #�ƻslen��0
  score <- rep(0,times=len)
  #�@�դ�����Ƽƶq�A����ơA�N��Ƥ���r����
  nr <- round(len / r)
  #�Y��ƶq�j��r�ث�
  if (nr > 0){
    
    rStart <-0
    rEnd <- 0
    #i=1:r
    for (i in 1:r){
      #�]�w�ҩl�ȩM���Ȫ����
      rStart = rEnd+1
      #�Y�ҩl�Ȥj��i*nr(�ռ�*�դ���Ƽ�)�Aif true�h���U�@��i
      if (rStart> i*nr) next
      #�Yi=r�A�w�g��̫�@�ծ�
      if (i == r){
        #�Y�ҩl�Ȥp�󵥩��ƪ��סA�h���ȵ����ƪ���
        #�Y�D�A�h���ȵ���ռ�*�դ���Ƽ�
        if(rStart<=len ) rEnd <- len else next
      }else{
        rEnd <- i*nr
      }
      #�]�wRecency������
      score[rStart:rEnd]<- r-i+1
      #�T�{�ۦPRency��ID����ƨ㦳�ۦP������
      s <- rEnd+1
      #��i=1,2,3,4�ɥB�ҩl�Ȥp�󵥩��ƪ��׮�
      if(i<r & s <= len){
        #�դ��ҩl�Ȩ�̫�@�����
        for(u in s: len){
          #�Y��դ��̫�@����Ʈ�
          if(rfm_data[rEnd,column]==rfm_data[u,column]){
            #�Ӳդ���=r-i+1
            score[u]<- r-i+1
            rEnd <- u
          }else{
            break;
          }
        }
        
      }
      
    }
    
  }
  return(score)
  
}

rs <-getIndependentScore(rfm_data)
#write.csv(rs,"E:\\Desk\\SPSS\\SPSS\\SPSS_Date\\csv\\rs.csv")

getScoreWithBreaks <- function(rfm_data,r,f,m) {
  
  #�p��Rency������
  len = length(r)
  R_Score <- c(rep(1,length(rfm_data[,1])))
  rfm_data <- cbind(rfm_data,R_Score)
  for(i in 1:len){
    if(i == 1){
      p1=0
    }else{
      p1=r[i-1]
    }
    p2=r[i]
    
    if(dim(rfm_data[p1<rfm_data$Recency & rfm_data$Recency<=p2,])[1]>0){
      rfm_data[p1<rfm_data$Recency & rfm_data$Recency<=p2,]$R_Score = len - i+ 2
    } 
  }
  
  #�p��Frequency������	
  len = length(f)
  F_Score <- c(rep(1,length(rfm_data[,1])))
  rfm_data <- cbind(rfm_data,F_Score)
  for(i in 1:len){
    if(i == 1){
      p1=0
    }else{
      p1=f[i-1]
    }
    p2=f[i]
    
    if(dim(rfm_data[p1<rfm_data$Frequency & rfm_data$Frequency<=p2,])[1]>0){
      rfm_data[p1<rfm_data$Frequency & rfm_data$Frequency<=p2,]$F_Score = i
    } 
  }
  if(dim(rfm_data[f[len]<rfm_data$Frequency,])[1]>0){
    rfm_data[f[len]<rfm_data$Frequency,]$F_Score = len+1
  } 
  
  #�p��Monetary������	
  len = length(m)
  M_Score <- c(rep(1,length(rfm_data[,1])))
  rfm_data <- cbind(rfm_data,M_Score)
  for(i in 1:len){
    if(i == 1){
      p1=0
    }else{
      p1=m[i-1]
    }
    p2=m[i]
    
    if(dim(rfm_data[p1<rfm_data$Monetary & rfm_data$Monetary<=p2,])[1]>0){
      rfm_data[p1<rfm_data$Monetary & rfm_data$Monetary<=p2,]$M_Score = i
    } 
  }
  if(dim(rfm_data[m[len]<rfm_data$Monetary,])[1]>0){
    rfm_data[m[len]<rfm_data$Monetary,]$M_Score = len+1
  } 
  
  #�Ƨ�
  rfm_data <- rfm_data[order(-rfm_data$R_Score,-rfm_data$F_Score,-rfm_data$M_Score),]
  #�p���`��
  Total_Score <- c(100*rfm_data$R_Score + 10*rfm_data$F_Score+rfm_data$M_Score)
  rfm_data <- cbind(rfm_data,Total_Score)
  
  return(rfm_data)
  
}

#���ƭȤ��
drawHistograms <- function(rfm_data,r=5,f=5,m=5){
  
  par(mfrow = c(f,r))
  
  names <-rep("",times=m)
  for(i in 1:m) names[i]<-paste("M",i)
  
  for (i in 1:f){
    for (j in 1:r){
      c <- rep(0,times=m)
      for(k in 1:m){
        tmpdf <-rfm_data[rfm_data$R_Score==j & rfm_data$F_Score==i & rfm_data$M_Score==k,]
        c[k]<- dim(tmpdf)[1]
        
      }
      if (i==1 & j==1) 
        barplot(c,col="lightblue",names.arg=names)
      else
        barplot(c,col="lightblue")
      if (j==1) title(ylab=paste("F",i))	
      if (i==1) title(main=paste("R",j))	
      
    }
    
  }
  
  par(mfrow = c(1,1))
  
} 

drawHistograms(rs)

hist(rfm_data$Recency)
hist(rfm_data$Frequency)
hist(rfm_data$Monetary)

#�ۦ�]�w���Ƭɽu
r <-c(149,154,164,169)
f <-c(12,13,14,15)
m <-c(03,27,35,37)
rs2<-getScoreWithBreaks(rfm_data,r,f,m)
drawHistograms(rs2)
hist(rs2$Recency)
hist(rs2$Frequency)
hist(rs2$Monetary)
#write.csv(rs2,"E:\\Desk\\SPSS\\SPSS\\SPSS_Date\\csv\\rs2.csv")
CI(rs$Recency,0.95)
CI(rs$Recency,0.65)
CI(rs$Frequency,0.95)
CI(rs$Frequency,0.65)
CI(rs$Monetary,0.95)
CI(rs$Monetary,0.65)