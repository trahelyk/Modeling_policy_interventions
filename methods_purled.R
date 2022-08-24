## ----setup, include=FALSE---------------------------------------------------------------------------------------------------------------------------
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


## ---------------------------------------------------------------------------------------------------------------------------------------------------
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


## ---------------------------------------------------------------------------------------------------------------------------------------------------
(hh_proto <- ggplot(data=hh,
                   aes(x=time, y=y)) +
  geom_point(alpha=0.5, size=2.5) +
  annotate(geom="text",
           x = 0,
           y = min(hh$y) - 8, 
           label=" Start of terraforming operation",
           hjust=0, 
           family = "xkcd") +
  annotate(geom="text",
           x = intervention,
           y = min(hh$y) - 8, 
           label=" Month 31: Implement safety program",
           hjust=0, 
           family = "xkcd") +
  geom_vline(xintercept = 31) +
  scale_y_continuous(name="Monthly operating costs, millions") +
  scale_x_continuous(breaks=seq(0, 60, 10)) +
  xkcdaxis(range(hh$time), range(hh$y)) +
  theme(legend.title = element_blank(),
        legend.position = "bottom"))



## ---------------------------------------------------------------------------------------------------------------------------------------------------
xbar_pre <- mean(hh$y[hh$post==0])
xbar_post <- mean(hh$y[hh$post==1])
delta <- round(xbar_post - xbar_pre)

hh_proto + 
  xkcdline(data = tibble(x1 = c(1, 32),
                         x2 = c(30, 59),
                         y1 = c(xbar_pre, xbar_post),
                         post = factor(c("Pre", "Post"))),
           aes(x=x1, xend=x2,
               y=y1, yend=y1,
               colour = post),
           mask=FALSE) +
  annotate(geom="text",
           x = 15, y = xbar_pre + 11,
           label = paste("bar(x)[pre] ==", rnd(xbar_pre, 0)),
           parse=TRUE,
           family="xkcd", size=10, color="#00BFC4") + 
  annotate(geom="text",
           x = 45, y = xbar_post + 11,
           label = paste("bar(x)[post] ==", rnd(xbar_post, 0)),
           parse=TRUE,
           family="xkcd", size=10, color="#F8766D") + 
  xkcdline(data = tibble(x = 31.5, xend = 31.5,
                         y = round(xbar_pre),
                         yend = round(xbar_post)),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
  xkcdline(data = tibble(x = 31.5 - 0.5, xend = 31.5 + 0.5,
                         y = round(xbar_pre),
                         yend = round(xbar_pre)),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
  xkcdline(data = tibble(x = 31.5 - 0.5, xend = 31.5 + 0.5,
                         y = round(xbar_post),
                         yend = round(xbar_post)),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
  xkcdline(data = tibble(x = 31.5, xend = 33.5,
                         y = xbar_pre + (delta/2),
                         yend = xbar_pre + (delta/2)),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
    annotate(geom="text",
           x = 34,
           y = xbar_pre + (delta/2),
           label= paste("delta ==", delta),
           parse=TRUE,
           hjust=0, size=10,
           family = "xkcd") +
  scale_color_discrete(c("red", "blue")) +
  theme(legend.title = element_blank(),
        legend.position = "none") 


## ---------------------------------------------------------------------------------------------------------------------------------------------------
hh_proto + 
  xkcdline(data = tibble(x1 = c(1, 32),
                         x2 = c(30, 59),
                         y1 = c(xbar_pre, xbar_post),
                         post = factor(c("Pre", "Post"))),
           aes(x=x1, xend=x2,
               y=y1, yend=y1,
               colour = post),
           mask=FALSE, lwd=1.5) +
  geom_line(data = tibble(x = c(32, 59), 
                         y = c(xbar_pre, xbar_pre)),
           aes(x=x, 
               y=y),
           lwd=1.5, lty=2, colour = "darkgrey") + 
  annotate(geom="text",
           x = 15, y = xbar_pre + 11,
           label = TeX("$E \\lbrack Y^1(t \\leq T_0) | D = 1 \\rbrack $"),
           size=10, color="#00BFC4") +
  annotate(geom="text",
           x = 45, y = xbar_post + 11,
           label = TeX("$E \\lbrack Y^1(t > T_0) | D = 1 \\rbrack $"),
           size=10, color="#F8766D") + 
  annotate(geom="text",
           x = 45, y = xbar_pre + 11,
           label = TeX("$E \\lbrack Y^0(t > T_0) | D = 1 \\rbrack $"),
           size=10, color="darkgrey") + 
  scale_color_discrete(c("red", "blue")) +
  theme(legend.title = element_blank(),
        legend.position = "none") 


## ----echo=TRUE, results='hold'----------------------------------------------------------------------------------------------------------------------
mean(hh$y[hh$post==1]) - mean(hh$y[hh$post==0])
with(hh, t.test(y ~ post))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_prepost <- lm(y ~ post + weather_index,
           data=hh)


## ---------------------------------------------------------------------------------------------------------------------------------------------------
tidy(lm_prepost) %>% 
  mutate(p.value = fmt.pval(p.value, include.p=FALSE))


## ----fig.width=3, fig.height=3----------------------------------------------------------------------------------------------------------------------
ggdag(tidy_dagitty(dagify(
                          y ~ x, 
                          y ~ z,
                          x ~ z,
                          exposure = "x",
                          outcome = "y"))) +
  theme_dag()



## ---------------------------------------------------------------------------------------------------------------------------------------------------
hh_proto


## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_its <- lm(y ~ time + post,
             data = hh)
hh_proto +
  geom_smooth(data = hh %>% filter(post==0) %>%
                mutate(y = predict(lm_its, 
                                   newdata=.)),
              method="lm", formula="y ~ x") +
  geom_smooth(data = tibble(post = rep(0, 29),
                            time = 32:60) %>%
                mutate(y = predict(lm_its, 
                                   newdata=.)),
              method="lm", formula="y ~ x",
              lty=2) + 
  geom_smooth(data = hh %>% filter(post==1) %>%
                mutate(y = predict(lm_its, 
                                   newdata=.)),
              method="lm", formula="y ~ x")



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_its <- lm(y ~ t + post,
             data = hh)


## ---------------------------------------------------------------------------------------------------------------------------------------------------
(coefs_its <- tidy(lm_its) %>% 
  mutate(p.value = fmt.pval(p.value, include.p=FALSE)))



## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_its2 <- lm(y ~ time*post,
             data = hh)
hh_proto +
  # Predicted pre-intervention
  geom_smooth(data = hh %>% filter(post==0) %>%
                mutate(y = predict(lm_its2, 
                                   newdata=.)),
              method="lm", formula="y ~ x") +
  # Predicted post-intervention counterfactual
  geom_smooth(data = tibble(post = rep(0, 29),
                            time = 32:60) %>%
                mutate(y = predict(lm_its2, 
                                   newdata=.)),
              method="lm", formula="y ~ x",
              lty=2) + 
  # Predicted post-intervention observed
  geom_smooth(data = hh %>% filter(post==1) %>%
                mutate(y = predict(lm_its2, 
                                   newdata=.)),
              method="lm", formula="y ~ x")



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_its2 <- lm(y ~ t*post,
             data = hh)


## ---------------------------------------------------------------------------------------------------------------------------------------------------
(coefs_its2 <- tidy(lm_its2) %>% 
  mutate(p.value = fmt.pval(p.value, include.p=FALSE)))


## ----warning=FALSE, message=FALSE, out.width="470px"------------------------------------------------------------------------------------------------
set.seed(3459)
tibble(Cost = rnorm(n=12, mean = 50000, sd=5000),
       Month = seq(1, 60, by=5)) %>%
  ggplot(aes(x=Month, y=Cost)) +
  # geom_point() + 
  # geom_line() +
  geom_smooth(se=FALSE) +
  scale_y_continuous(limits=c(46000, 52000)) +
    theme(legend.title = element_blank(),
        legend.position = "none",
        axis.title = element_text(size=30),
        axis.text = element_text(size=15 )) 


## ---------------------------------------------------------------------------------------------------------------------------------------------------
(hhf_proto <- ggplot(data=hhf,
       aes(x=time, y=y)) +
  geom_point(aes(group=colony, color=colony),
             alpha=0.4, size=2.5) +
    annotate(geom="text",
           x = 0,
           y = min(hhf$y) - 11, 
           label=" Start of terraforming operation",
           hjust=0, 
           family = "xkcd") +
    annotate(geom="text",
           x = intervention,
           y = min(hhf$y) - 11, 
           label=" Month 31: Implement safety program",
           hjust=0, 
           family = "xkcd") +
  geom_vline(xintercept = 31) +
  scale_y_continuous(name="Monthly operating costs, millions") +
  scale_x_continuous(breaks=seq(0, 60, 10)) +
  scale_color_discrete(c("red", "blue")) + 
  xkcdaxis(range(hhf$time), range(hhf$y)) +
  theme(legend.title = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        legend.position = c(0.2, 0.8)))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
xbar_0 <- mean(hhf$y[hhf$treat==1 & hhf$post==0])
xbar_1 <- mean(hhf$y[hhf$treat==1 & hhf$post==1])
delta <- round(xbar_1) - round(xbar_0)

hhf_proto +
  xkcdline(data = tibble(x1 = c(32),
                         x2 = c(59),
                         y1 = c(xbar_1),
                         post = factor(c("Hadley's Hope"))),
           aes(x=x1, xend=x2,
               y=y1, yend=y1,
               colour = post),
           mask=FALSE) +
  annotate(geom="text",
           x = 15, y = xbar_0 + 12,
           label = paste("bar(x)['Hadleys NOPE'] ==", rnd(xbar_0, 0)),
           parse=TRUE,
           family="xkcd", size=10, color="black") + 
  annotate(geom="text",
           x = 45, y = xbar_1 - 12,
           label = paste("bar(x)['Hadleys Hope'] ==", rnd(xbar_1, 0)),
           parse=TRUE,
           family="xkcd", size=10, color="#00BFC4") + 
  xkcdline(data = tibble(x = 2 - 0.5, xend = 30 + 0.5,
                         y = round(xbar_0)-2,
                         yend = round(xbar_0)-2),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE)



## ---------------------------------------------------------------------------------------------------------------------------------------------------
xbar_0 <- mean(hhf$y[hhf$treat==0 & hhf$post==1])
xbar_1 <- mean(hhf$y[hhf$treat==1 & hhf$post==1])
delta <- round(xbar_1) - round(xbar_0)

hhf_proto +
  xkcdline(data = tibble(x1 = c(32, 32),
                         x2 = c(59, 59),
                         y1 = c(xbar_0, xbar_1),
                         post = factor(c("Fiorina 161", "Hadley's Hope"))),
           aes(x=x1, xend=x2,
               y=y1, yend=y1,
               colour = post),
           mask=FALSE) +
  annotate(geom="text",
           x = 45, y = xbar_0 + 12,
           label = paste("bar(x)['Fiorina 161'] ==", rnd(xbar_0, 0)),
           parse=TRUE,
           family="xkcd", size=10, color="#F8766D") + 
  annotate(geom="text",
           x = 45, y = xbar_1 - 12,
           label = paste("bar(x)['Hadleys Hope'] ==", rnd(xbar_1, 0)),
           parse=TRUE,
           family="xkcd", size=10, color="#00BFC4") + 
  xkcdline(data = tibble(x = 45.5, xend = 45.5,
                         y = round(xbar_0) - 2,
                         yend = round(xbar_1) + 2),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
  xkcdline(data = tibble(x = 45.5 - 0.5, xend = 45.5 + 0.5,
                         y = round(xbar_0)-2,
                         yend = round(xbar_0)-2),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
  xkcdline(data = tibble(x = 45.5 - 0.5, xend = 45.5 + 0.5,
                         y = round(xbar_1)+2,
                         yend = round(xbar_1)+2),
           aes(x=x, xend=xend,
               y=y, yend=yend),
           mask=FALSE) +
    annotate(geom="text",
           x = 46,
           y = xbar_0 + (delta/2),
           label= paste("delta ==", delta),
           parse=TRUE,
           hjust=0, size=10,
           family = "xkcd") 



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
mean(hhf$y[hhf$treat==1]) - mean(hhf$y[hhf$treat==0])
with(hhf, t.test(y ~ post))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_2grp <- lm(y ~ treat + weather_index,
           data=hhf %>% filter(post==1))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
md(tidy(lm_2grp) %>% 
  mutate(p.value = fmt.pval(p.value, include.p=FALSE)))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_cits <- lm(y ~ time*post + time*treat + treat*post + I(treat * post * time),
             data = hhf)

hhf_proto +
  # Predicted pre-intervention
  geom_smooth(data = hhf %>% filter(post==0) %>%
                mutate(y = predict(lm_cits, 
                                   newdata=.)),
              aes(group=colony, color=colony),
              method="lm", formula="y ~ x") +
  # Predicted post-intervention
  geom_smooth(data = hhf %>% filter(post==1) %>%
                mutate(y = predict(lm_cits, 
                                   newdata=.)),
              aes(group=colony, color=colony),
              method="lm", formula="y ~ x") 
  



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_cits <- lm(y ~ t*post + t*treat + treat*post + I(treat * post * t),
             data = hhf)


## ----echo=FALSE-------------------------------------------------------------------------------------------------------------------------------------
(coefs_cits <- tidy(lm_cits) %>% 
  mutate(p.value = fmt.pval(p.value, include.p=FALSE)))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
summary(multcomp::glht(lm_cits, 
             linfct = matrix(c(0, 0, 0, 0, 12, 0, 0, 1), 1)))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_did <- lm(y ~ treat*post,
             data=hhf)

xbar_pre0 <- mean((hhf %>% filter(post==0 & treat==0) %>%
            mutate(y = predict(lm_did, 
                               newdata=.)) %>%
             pull(y)))

xbar_pre1 <- mean((hhf %>% filter(post==0 & treat==1) %>%
            mutate(y = predict(lm_did, 
                               newdata=.)) %>%
             pull(y)))

xbar_post0 <- mean((hhf %>% filter(post==1 & treat==0) %>%
            mutate(y = predict(lm_did, 
                               newdata=.)) %>%
             pull(y)))

xbar_post1 <- mean((hhf %>% filter(post==1 & treat==1) %>%
            mutate(y = predict(lm_did, 
                               newdata=.)) %>%
             pull(y)))

hhf_proto +
  # Predicted pre-intervention
  geom_smooth(data = hhf %>% filter(post==0) %>%
                mutate(y = predict(lm_did, 
                                   newdata=.)),
              aes(group=colony, color=colony),
              method="lm", formula="y ~ x") +
  # Predicted post-intervention
  geom_smooth(data = hhf %>% filter(post==1) %>%
                mutate(y = predict(lm_did, 
                                   newdata=.)),
              aes(group=colony, color=colony),
              method="lm", formula="y ~ x") +
  geom_line(data = tibble(x = c(31, 31.5, 31.5, 32, 31, 33, 33), 
                         y = c(xbar_pre0, xbar_pre0, xbar_post0, xbar_post0, 
                               xbar_pre1, xbar_pre1, xbar_post1),
                         colony = c(rep("Fiorina 161", 4), rep("Hadley's Hope", 3))),
           aes(x=x, 
               y=y, 
               colour = colony),
           lty=2) + 
  annotate(geom="text",
           x = 33.5, y = 600,
           label = "delta['d=1']",
           parse=TRUE,
           hjust=0,
           family="xkcd", size=10, color="#00BFC4") +
  annotate(geom="text",
           x = 32, y = 640,
           label = "delta['d=0']",
           parse=TRUE,
           hjust=0,
           family="xkcd", size=10, color="#F8766D") +
  annotate(geom="text",
           x = 35, y = 550,
           label = "'DiD' == delta['d=1'] - delta['d=0']",
           parse = TRUE, hjust=0,
           family = "xkcd", size=12)
  


## ----echo = FALSE, results="asis"-------------------------------------------------------------------------------------------------------------------
hhf %<>%
  mutate(t_f = factor(t),
         tx_post = treat==1 & post==1)

fiorina <- hhf %>% filter(colony=="Fiorina 161")
hadley <-  hhf %>% filter(colony=="Hadley's Hope")

fiorina_pre <- mean(fiorina %>% filter(post==0) %>% pull(y))
fiorina_post <- mean(fiorina %>% filter(post==1) %>% pull(y))
fiorina_diff <- fiorina_post - fiorina_pre

hadley_pre <- mean(hadley %>% filter(post==0) %>% pull(y))
hadley_post <- mean(hadley %>% filter(post==1) %>% pull(y))
hadley_diff <- hadley_post - hadley_pre

md(tibble(Colony = c("Fiorina 161 (comparison)", "Hadley's Hope (test)"),
       Pre = round(c(fiorina_pre, hadley_pre)),
       Post = round(c(fiorina_post, hadley_post))) %>%
  mutate(Difference = Post - Pre))



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
31-93


## ---------------------------------------------------------------------------------------------------------------------------------------------------
tidy(lm_did <- lm(y ~ treat*post,
                  data=hhf))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_did <- lm(y ~ tx_post + t_f + colony,
                  data=hhf)


## ---------------------------------------------------------------------------------------------------------------------------------------------------
tidy(lm_did) %>%
  filter(!str_detect(term, "^t_f"))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_pt <- lm(y ~ t*colony,
   data=hhf %>% filter(post==0))

hhf_proto +
  # Predicted pre-intervention
  geom_smooth(data = hhf %>% filter(post==0) %>%
                mutate(y = predict(lm_pt, 
                                   newdata=.)),
              aes(group=colony, color=colony),
              method="lm", formula="y ~ x") 


## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_pt <- lm(y ~ t*treat,
   data=hhf %>% filter(post==0))
summary(lm_pt)


## ---------------------------------------------------------------------------------------------------------------------------------------------------
colonies %<>%
  mutate(t_f = factor(t),
         tx_post = treat==1 & post==1)

(colonies_proto <- ggplot(data=colonies,
       aes(x=time, y=y)) +
  geom_point(aes(group=colony, color=colony),
             alpha=0.4, size=2.5) +
    annotate(geom="text",
           x = 0,
           y = min(colonies$y) - 11, 
           label=" Pre",
           hjust=0, 
           family = "xkcd") +
    annotate(geom="text",
           x = intervention,
           y = min(colonies$y) - 11, 
           label=" Post",
           hjust=0, 
           family = "xkcd") +
  geom_vline(xintercept = 31) +
  scale_y_continuous(name="Monthly operating costs, millions") +
  scale_x_continuous(breaks=seq(0, 60, 10)) +
  xkcdaxis(range(colonies$time), range(colonies$y)) +
  theme(legend.title = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        legend.position = c(0.2, 0.7)) +
  guides(fill=guide_legend(ncol=2)))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
(colonies_2p <- colonies %>%
  group_by(colony, treat, post) %>%
  summarise(colony_effect = mean(colony_effect),
            weather_index = mean(weather_index),
            y = mean(y)) %>%
  ungroup() %>%
   mutate(tx_post = as.numeric(treat==1 & post==1)) %>%
   select(colony, treat, post, tx_post, weather_index, y))



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
(colonies_diff <- colonies_2p %>%
       pivot_wider(names_from = post,
                   values_from = c(tx_post, weather_index, y)) %>%
       mutate(delta_y = y_1 - y_0,
              delta_txpost = tx_post_1 - tx_post_0,
              delta_weather = weather_index_1 - weather_index_0))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_fe1 <- lm(delta_y ~ delta_txpost, data = colonies_diff)
tidy(lm_fe1)


with(colonies_2p, by(y, tx_post, summary))
with(colonies_diff, by(delta_y, delta_txpost, summary))


## ---------------------------------------------------------------------------------------------------------------------------------------------------
lm_fe2 <- lm(y ~ tx_post + colony + post, data=colonies_2p)
tidy(lm_fe2) %>% filter(!str_detect(term, "^colony"))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
lm_demean <- colonies %>%
  group_by(colony) %>%
  mutate(y_star = y - mean(y),
         tx_post_star = as.numeric(tx_post) - mean(as.numeric(tx_post)),
         x_star = weather_index - mean(weather_index)) %>%
  lm(y_star ~ tx_post_star + x_star + t_f,
     data=.)

# Results
tidy(lmtest::coeftest(lm_demean, 
                      sandwich::vcovHC(lm_demean, cluster=colonies$colony))) %>%
  filter(!str_detect(term, "^colony|^t_f"))


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
tic("lm_robust()")
tidy(estimatr::lm_robust(y ~ tx_post + weather_index,
          fixed_effects = ~ colony + t_f,
          clusters = colony,
          se_type = "stata",
          data=colonies))
toc()


## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
bench <- map_dfr(1:30, 
                 function(i) {
                   tic(paste0("lm() iteration ", i))
                   # Fit the model
                   lm_fe <- lm(y ~ tx_post + weather_index + colony + t_f,
                               data=colonies)
                   
                   # Estimate heteroskedasticity-consistent covariance matrix
                   vcv_lm_fe <- sandwich::vcovHC(lm_fe, cluster=colonies$colony) 
                   
                   # Results
                   rslts <- tidy(lmtest::coeftest(lm_fe, vcv_lm_fe)) %>%
                     filter(!str_detect(term, "^colony|^t_f"))
                   tt_lm <- toc()
                   
                   tic(paste0("lm_robust() iteration ", i))
                   rslts2 <- tidy(estimatr::lm_robust(y ~ tx_post + weather_index,
                                                      fixed_effects = ~ colony + t_f,
                                                      clusters = colony,
                                                      se_type = "stata",
                                                      data=colonies))
                   tt_lmr <- toc()
                   
                   return(tibble(lm = tt_lm$toc - tt_lm$tic,
                                 lm_robust = tt_lmr$toc - tt_lmr$tic))
                 })

with(bench, t.test(lm, lm_robust))





## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
# Fit the model
lm_fe <- lm(y ~ treat*post + colony + t_f,
                 data=colonies)

# Estimate heteroskedasticity-consistent covariance matrix
vcv_lm_fe <- sandwich::vcovHC(lm_fe, cluster=colonies$colony) 

# Results
tidy(lmtest::coeftest(lm_fe, vcv_lm_fe)) %>%
  filter(!str_detect(term, "^colony|^t_f"))



## ----echo=TRUE--------------------------------------------------------------------------------------------------------------------------------------
# Fit the model
lm_fe <- lm(y ~ tx_post + colony + t_f,
                 data=colonies)

# Estimate heteroskedasticity-consistent covariance matrix
vcv_lm_fe <- sandwich::vcovHC(lm_fe, cluster=colonies$colony) 

# Results
tidy(lmtest::coeftest(lm_fe, vcv_lm_fe)) %>%
  filter(!str_detect(term, "^colony|^t_f"))


