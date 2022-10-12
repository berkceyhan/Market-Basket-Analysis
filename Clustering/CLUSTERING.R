## FIRST CUSTOMER SEGMENTATION: BASED ON AMOUNT SPENT AND NUMBE OF VISITS IN LAST 3 MONTHS

db1<- read.csv('DB_clustering_1.csv', header=T)
# Scaling of the data
x<-scale(db1)
## We perform the clustering on the second column (number_trans, that is the number of visits in last 3 months) and third column(Tot amount)
# NOTE: The values of " number of trans" have been obtained by aggregating,per each customer, all the different transactions 
# done in the same purchase moment/day so that we could count,per each customer, the REAL number of visits during last 3 months.
x<-x[,c(2,3)]

# Trying different 'nstart'
km.out <- kmeans(x,2,nstart=1) # one seed set
km.out$tot.withinss
km.out <- kmeans(x,2,nstart=20) # 20 seed set
km.out$tot.withinss
# K SELECTION
withinss <- NULL
for(i in 1:10) # loop on K
  withinss <- c(withinss,kmeans(x,i,nstart=20)$tot.withinss) # for every run we save with-in-ss
# Plot the withinss as a function of K
x11()
plot(1:10,withinss,type='b', xlab='K', main="Within variability while K changes")

# After selcting k=2 we run kmeans
km.out <- kmeans(x,2)
km.out
# Plot the points
x11()
plot(x, col=(km.out$cluster+1), main="K-Means Clustering Results with K=2",  pch=20, cex=2, xlab='X.1', ylab='X.2')

## SECOND CUSTOMER SEGMENTATION: BASED ON THE SCORES OF THE 9 FACTORS SELECTED FROM THE FACTOR ANALYSES

db2<- read.csv('scores_db.csv', header=T)

# Exlcude the first column that is customer id since the alghoritm will be applied only on the remaining 9 columns (9 factors)
y=db2[,-1]

# plot the data
x11()
plot(y)#,col=which,pch=19,xlab='x1',ylab='x2')
#plot(y, xlab='x1',ylab='x2')

##First let's try with k-means
# K SELECTION
withinss <- NULL
for(i in 1:10) # loop on K
  withinss <- c(withinss,kmeans(y,i,nstart=20)$tot.withinss) # for every run we save with-in-ss
# Plot the withinss as a function of K
x11()
plot(1:10,withinss,type='b', xlab='K', main="Within variability while K changes")

#Results are not satisfying (it might be due to the high number of variables on which we perform clustering) so let's applu hierarchcial clustering

##Hierarchical clustering

# Complete Linkage, Euclidean Distance
hc.complete <- hclust(dist(y), method="complete")
hc.complete

# Average Linkage, Euclidean Distance
hc.average <- hclust(dist(y), method="average")

# Single Linkage, Euclidean Distance
hc.single <- hclust(dist(y), method="single")

# Ward-linkage, Euclidean Distance
hc.ward <- hclust(dist(y), method="ward.D")

#we can try also with correlation based distance
dd <- as.dist(1-cor(t(y)))

# Complete Linkage,Distance based on correlation
x.cc<-hclust(dd, method="complete")

# Average Linkage,Distance based on correlation
x.ca<-hclust(dd, method="average")

# Ward Linkage,Distance based on correlation
x.cw<-hclust(dd, method="ward.D")

#Let's compare the dendograms of different hc
x11()
par(mfrow=c(2,4))
plot(hc.complete,main="Complete Linkage, Euclidean distance", xlab="", sub="", cex=.9)
plot(hc.average, main="Average Linkage,Euclidean distance", xlab="", sub="", cex=.9)
plot(hc.single, main="Single Linkage,Euclidean distance", xlab="", sub="", cex=.9)
plot(hc.ward, main="Ward Linkage,Euclidean distance", xlab="", sub="", cex=.9)
plot(x.cc,main="Complete Linkage,Correlation distance", xlab="", sub="", cex=.9) # Chosen one
plot(x.ca, main="Average Linkage,Correlation distance", xlab="", sub="", cex=.9)
plot(x.cw, main="Ward Linkage,Correlation distance", xlab="", sub="", cex=.9)

#The best results seem to be obtained with correlation based distance and complete linkage (also because we are interested in clustering customers
# based on similar purchase habits, so correlation is the most approriate type one )
#Moreover, by looking at the lenght of the brances, cutting the tree so that to have 8 clusters seemes to be the best choice.

cluster <- cutree(x.cc, k = 8)

# to see the labels
cluster
#add to the orignal db the column with labels from clustering
db2[,11]=cluster

write.csv(db2, 'HierarchicalClusteringResults.csv')






