ka <- function(T,H){
  T_fac <- (T-20.615)/10.585
  H_fac <- (H-45.235)/28.665
  S <- (0.1-0.95)/0.95
  ka <- 0.16030+0.041018*T_fac+0.02176*H_fac+0.14369*S+0.02636*T_fac*S
  return(ka)
}

ks <- function(T,H){
  half_life <- 32.426272-(0.622108*T)-(0.153707*H)
  ks <- log(2)/half_life
  return(ks)
}

Pwr <- function(x){
  if(x$Hs==1){
    return(0)
  } else{
    I <- 1
    q <- 18.38
    p <- 0.3
    Q <- as.numeric(x$Q)
    t <- as.numeric(x$Du)/x$Fh
    Ltype <- as.numeric(x$Location.Type)
    upper <- -(I*q*p*t)/Q
    pwr <- (1-exp(upper))*Ltype
    #print(pwr)
    return(pwr)
  }
}