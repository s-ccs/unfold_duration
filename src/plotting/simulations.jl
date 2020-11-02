import CSV
using RCall

d = CSV.read("local/2020-09-24_simulationResults.csv")

@rput d

## --


R"""
library(dplyr)
library(ggplot2)
library(ggbeeswarm)
library(ggpubr)


ggplot(d%>%filter(overlapdist=="uniform"))+ 
    aes(x=shape,y=normMSE,color=formula) +
    geom_quasirandom(dodge=0.5)+
    facet_grid(overlap~noise+overlapmod)+  theme_pubr()
"""
R"""
ggplot(d%>%filter(overlapdist=="uniform"))+ 
    aes(x=formula,y=normMSE,color=overlapmod) +
    geom_quasirandom(dodge=0.5)+
    facet_grid(overlap~noise+shape)+  theme_pubr()+  scale_x_discrete(guide = guide_axis(n.dodge = 4))
"""
R"""
ggplot(d%>%filter(overlapdist=="uniform"&overlapmod=="overlapmod-2.0.mat"))+ 
    aes(x=shape,y=MSE,color=noise) +
    geom_quasirandom(dodge=0.5)+
    facet_grid(overlap~overlapmod+formula)+  theme_pubr()+  scale_x_discrete(guide = guide_axis(n.dodge = 4))
"""

#---

R"""
d%>%
    filter(overlapdist=="uniform"&overlapmod=="overlapmod-1.5.mat"&noise=="noise-1.00"&overlap=="overlap-1" & (formula != "y~1" & formula != "theoretical"))%>%
    mutate(formula =factor(formula,levels=unique(formula)[c(2,1,4,3)]))%>% 
ggplot()+ 
    aes(x=shape,y=normMSE,color=formula) +
    geom_quasirandom(dodge=0.5)+
    geom_hline(aes(yintercept=0)) +
    #geom_text(aes(0,0,label = "Best", vjust = -1,hjust=-0.5))+
    geom_hline(aes(yintercept=1)) + scale_color_discrete(guide=F)+
    #geom_text(aes(0,1,label = "Constant", vjust = -1,hjust=-0.5))+
    theme_pubr()+  scale_x_discrete(labels=c())+scale_y_continuous(breaks=c(0,1),label=c("best","constant"))+ylab("norm. MSE to ground truth")+xlab("")
"""