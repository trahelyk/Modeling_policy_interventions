# library(multcomp)
library(trahelyk)
library(grid)
library(xkcd)
library(ggdag)
library(latex2exp)
library(tictoc)
library(tidyr)
library(estimatr)
library(sandwich)
library(lmtest)
knitr::opts_chunk$set(echo = FALSE,
                      warning=FALSE,
                      fig.width=10)


intervention <- 31
set.seed(9583)
colonies <- tibble(colony = rep(c("Hadley's Hope",
                                  "Relitor",
                                  "Arceon",
                                  "Articus",
                                  "Arcturus",
                                  "Fiorina 161",
                                  "Argos",
                                  "Atlas",
                                  "Crysalis",
                                  "Cyrus"), each = 60),
                   time = rep(1:60, times=10),
                   t = rep(-30:29, times=10),
                   colony_effect = rep(rnorm(n=10, mean=0, sd=10), each=60)) %>%
  mutate(colony_effect = case_when(colony=="Fiorina 161" ~ 25,
                                   TRUE ~ colony_effect)) %>%
  mutate(weather_index = runif(n=nrow(.), min=0, max=10),
         treat = rep(c(1, 0), each=60*5),
         post = as.numeric(time > intervention)) %>% 
  mutate(y = 500 + (3 * time) + 
           (20 * treat) + 
           (-40 * treat * post) + 
           (-1 * treat * post * (time-intervention)) + 
           (5 * weather_index) +
           colony_effect + 
           rnorm(n=nrow(.), mean=0, sd=20))

colonies$colony_effect[colonies$colony=="Fiorina 161"] <- -18

hh <- colonies %>% filter(colony=="Hadley's Hope")

hhf <- colonies %>% filter(colony %in% c("Hadley's Hope", "Fiorina 161")) %>%
  mutate(colony_tx = factor(treat, levels=c(0, 1),
                            labels=c("Fiorina 161 --comparison--",
                                     "Hadley's Hope --intervention--")))

head(hh)