## 
```{r}
ggplot(data=hh,
       aes(x=time, y=y)) +
  xkcdaxis(range(hh$time), range(hh$y)) +
  geom_vline(xintercept = intervention) +
  annotate(geom="text",
           # x = intervention, 
           x = 31,
           y = min(hh$y) + 5, 
           label=" Month 31: Implement safety program",
           hjust=0, 
           family = "xkcd") +
  geom_point(alpha=0.3, size=2.5) +
  geom_smooth(data=hh %>% filter(post==0),
              se=FALSE,
              method="lm", formula="y ~ x") +
  geom_smooth(data=hh %>% filter(post==1), 
              se=FALSE,
              method="lm", formula="y ~ x") +
  scale_y_continuous(name="Monthly operating costs, millions")

```