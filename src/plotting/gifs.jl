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

ggplot(d%>%filter(overlapdist=="uniform"))+ 
    aes(x=formula,y=normMSE,color=overlapmod) +
    geom_quasirandom(dodge=0.5)+
    facet_grid(overlap~noise+shape)+  theme_pubr()+  scale_x_discrete(guide = guide_axis(n.dodge = 4))

ggplot(d%>%filter(overlapdist=="uniform"&overlapmod=="overlapmod-2.0.mat"))+ 
    aes(x=shape,y=MSE,color=noise) +
    geom_quasirandom(dodge=0.5)+
    facet_grid(overlap~overlapmod+formula)+  theme_pubr()+  scale_x_discrete(guide = guide_axis(n.dodge = 4))
"""
