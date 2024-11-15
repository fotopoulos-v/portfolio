# Titanic dataset analysis

data = read.csv('Titanic_Dataset.csv', na.strings="")


# Clarifications:
# Pclass: Ticket class indicating the socio-economic status of the passenger. 
# It is categorized into three classes: 1 = Upper, 2 = Middle, 3 = Lower.

# SibSp: The number of siblings or spouses aboard the Titanic for 
# the respective passenger.

# Parch: The number of parents or children aboard the Titanic for the 
# respective passenger.

# Ticket: The ticket number assigned to the passenger.

# Fare: The fare paid by the passenger for the ticket.

# Cabin: The cabin number assigned to the passenger, if available.

# Embarked: The port of embarkation for the passenger. It can take one 
# of three values: C = Cherbourg, Q = Queenstown, S = Southampton.

# Boat: If the passenger survived, this column contains the identifier of 
# the lifeboat they were rescued in.

# Body: If the passenger did not survive, this column contains the 
# identification number of their recovered body, if applicable.

# Home.dest: The destination or place of residence of the passenger.


# 1) DATA EXPLORATION:
# Number of survivors
cat('\nNumber of survivors:', length(data$survived[data$survived==1]), 'of', nrow(data))
# Number of deceased
cat('\nNumber of deceased:', length(data$survived[data$survived==0]), 'of', nrow(data))
# Number of women
cat('\nNumber of women:', length(data$sex[data$sex=='female']), 'of', nrow(data))
# Number of men
cat('\nNumber of men:', length(data$sex[data$sex=='male']), 'of', nrow(data))
# Proportion (%) of men 
cat('\nProportion (%) of men:', round(length(data$sex[data$sex=='male'])/nrow(data)*100,2))
# Proportion (%) of survivals
cat('\nProportion (%) of survivals:', round(length(data$survived[data$survived==1])/nrow(data)*100,2))
# Proportion (%) of women survived
cat('\nProportion (%) of women survived:', round(length(data$survived[data$survived==1 & data$sex=='female'])/
        length(data$sex[data$sex=='female'])*100,2))
# Proportion (%) of men survived
cat('\nProportion (%) of men survived:', round(length(data$survived[data$survived==1 & data$sex=='male'])/
        length(data$sex[data$sex=='male'])*100,2))
# distribution of 'ages'
hist(data$age, breaks=20, xlab='Age', main='Age distribution')
# Proportion (%) of ages between 20-30
round(length(data$age[data$age>=20 & data$age<=30])/
        nrow(data)*100,2)
# Proportion (%) of ages between 20-30 that survived
cat('\nProportion (%) of ages between 20-30 that survived:',round(length(data$age[data$age>=20 & data$age<=30 & data$survived==1])/
        length(data$age[data$age>=20 & data$age<=30])*100,2))
# Proportion (%) of ages between 0-15 that survived
cat('\nProportion (%) of ages between 0-15 that survived:',round(length(data$age[data$age>=0 & data$age<=20 & data$survived==1])/
        length(data$age[data$age>=0 & data$age<=20])*100,2))
# Proportion (%) of ages from 30 and above that survived
cat('\nProportion (%) of ages from 30 and above that survived:', round(length(data$age[data$age>30 & data$survived==1])/
        length(data$age[data$age>30])*100,2))
# distribution of 'fare' cost
hist(data$fare, xlim=c(0,500), breaks=20, main = 'Fare\'s price', xlab='Dollars ($)')
# Proportion (%) of travelers with fare above 100 dollars that survived
cat('\nProportion (%) of travelers with fare above 100 dollars that survived:', round(length(data$fare[data$fare>100 & data$survived==1])/
        length(data$fare[data$fare>100])*100,2))
# Proportion (%) of women with fare above 100 dollars 
cat('\nProportion (%) of women with fare above 100 dollars:', round(length(data$fare[data$fare>100 & data$sex=='female'])/
        length(data$fare[data$fare>100])*100,2))
# Proportion (%) of men with fare above 100 dollars that survived
cat('\nProportion (%) of men with fare above 100 dollars that survived:', round(length(data$fare[data$fare>100 & data$sex=='male' & data$survived==1])/
        length(data$fare[data$fare>100 & data$sex=='male'])*100,2))
cat('\n\n')

# 2) DATA PREPROCESSING
# we remove the 'survived' column as well as some unnecessary columns such as 'name', 'ticket number' etc.
# and store it to data_titanic object
data_titanic <- data[,c(-2,-3,-8,-10,-12,-13,-14)]
# replacing NA values in the 'embarked' columns with the most frequent value (mode)
mode_embarked <- names(which.max(table(data_titanic$embarked)))
data_titanic$embarked[is.na(data_titanic$embarked)] <- mode_embarked

# perform one-hot encoding in the 'embarked' column in order to replace it later
encoding1 <- model.matrix(~ embarked - 1, data = data_titanic)
# removing the 'embarked column'
data_titanic <- data_titanic[,-7]
# adding the encoded data from the 'embarked' encoding that we performed earlier
data_titanic <- cbind(data_titanic, encoding1)

# replacing 'male' values with 1 and 'female' values with 0
data_titanic$sex[data_titanic$sex=='male'] <- 1
data_titanic$sex[data_titanic$sex=='female'] <- 0
# transform the values of the 'sex' column to numeric
data_titanic$sex <- as.numeric(data_titanic$sex)

# There are quite a few missing values in the 'age' column (~20% of the total records).
# We will fill these values based on the following idea: The age will be the mean age of 
# cases with the same 'sibsp' (siblings-spouses) and 'parch' (parents-children).
# First we calculate all the different combinations and store it to a dataframe
combinations_of_sibsp_parch <- unique(data_titanic[,c(4,5)])
# then we create a list with the calculated values of age for these combinations
age_replacements = list()
for (i in 1:nrow(combinations_of_sibsp_parch)) {
  age <- mean(data_titanic$age[data_titanic$sibsp==combinations_of_sibsp_parch[i,1] &
                           data_titanic$parch==combinations_of_sibsp_parch[i,2]], na.rm=TRUE)
  age <- ifelse(is.nan(age), 40, age)
  age_replacements <- append(age_replacements, age)
}

# we add that column to the combinations dataframe
pairs_with_age_replacement <- cbind(combinations_of_sibsp_parch, as.matrix(age_replacements))
# now we obtain the indices of the rows of which the age value is NaN
indices_of_na_ages <- which(is.na(data_titanic$age))

# we create a 'for-loop' to calculate the 'age' values using the idea that we mentioned before
for (i in indices_of_na_ages) {
  values_list = list() 
  for (j in 1:25) {
    value = ifelse(data_titanic[i,'sibsp']==pairs_with_age_replacement[[j,1]] &
                     data_titanic[i,'parch']==pairs_with_age_replacement[[j,2]], 
                   pairs_with_age_replacement[[j,3]], NA)
    values_list = append(values_list, value)
    value = round(sum(unlist(values_list), na.rm=TRUE)) 
    }
    data_titanic$age[i] <- value
  }

# there is also one NA value in the 'fare' column. We decide to replace it with
# the mean value of the fares of the records with the same 'pclass' as that of the
# record with the missing 'fare' value
# Firstly we find the pclass of the row with the NA value in the 'fare' column
p_class_of_missing <- data_titanic$pclass[which(is.na(data_titanic$fare))]
# then we replace it with the mean value of the fares of the records with the 
# same pclass
data_titanic$fare[is.na(data_titanic$fare)] <- 
  mean(data_titanic$fare[data_titanic$pclass==p_class_of_missing], na.rm=TRUE)


# it is a good practice to apply k-fold cross validation in order to ensure that
# the accuracy results that we will obtain for each algorithm used for predictions
# are not a result of luck (either good or bad).

# we shuffle the rows of the dataset in order to remove any initial structure of
# the data 
shuffled_index <- sample(1:nrow(data_titanic)) 
data_titanic <- data_titanic[shuffled_index,]
# we also alter the initial dataset to have the same indexing as the data_titanic because it
# has the 'survived'column which is needed for the test sets.
data <- data[shuffled_index,]


# now that we have only numeric values we can perform Principal Component Analysis (PCA).
# the 'scale=TRUE' parameter standardizes the data so as to have equal magnitudes for 
# every column
pca_object <- prcomp(data_titanic, center=TRUE, scale=TRUE)
# we take a look at the new variables (Principal Components)
summary(pca_object)
# we see that with the first 7 principal components we can explain the 96% of
# the total variance
# so we make a dataframe using only the first 7 principal components
pca_data_titanic <- as.data.frame(pca_object$x[,1:7])

# we also scale the data_titanic object
data_titanic <- scale(data_titanic)

# we will split the dataset to k=10 folds of about 130 rows each
k_fold_list = list(1:130, 131:260, 261:390, 391:520, 521:650, 
                   651:780, 781:910, 911:1040, 1041:1170, 1171:1309)

# and we will create a for-loop with 10 iterations. In each iteration the 
# algorithms will use one fold as a test set (about 10% of the data) and the 
# rest will be used for training (about 90% of the data). In this way the whole
# dataset will have been used both as test set and as training set (in different
# iterations) and we will have mitigated as much as possible the factor of luck
# in our models' metric results.

# disabling the display of warning messages
options(warn = -1)

# loading the required packages 
library(class)
library(pROC)
library(e1071)
library(randomForest)
library(rpart)
library(neuralnet)
# creating empty vectors that are needed in the following for-loop
knn_acc_vector <- vector()
knn_auc_vector <- vector()
knn_rec_vector <- vector()
knn_pre_vector <- vector()
svm_acc_vector <- vector()
svm_auc_vector <- vector()
rf_acc_vector <- vector()
rf_auc_vector <- vector()
nbayes_acc_vector <- vector()
nbayes_auc_vector <- vector()
dtree_acc_vector <- vector()
dtree_auc_vector <- vector()
logr_acc_vector <- vector()
logr_auc_vector <- vector()
ann_acc_vector <- vector()
ann_auc_vector <- vector()
ann_rec_vector <- vector()
ann_pre_vector <- vector()
svm_rec_vector <- vector()
svm_pre_vector <- vector()
rf_rec_vector <- vector()
rf_pre_vector <- vector()
nbayes_rec_vector <- vector()
nbayes_pre_vector <- vector()
dtree_rec_vector <- vector()
dtree_pre_vector <- vector()
logr_rec_vector <- vector()
logr_pre_vector <- vector()

# we suppress the display of some unnecessary informative messages
suppressMessages({
# this is the main for-loop that runs all the algorithms
for (i in 1:length(k_fold_list)) {
  train_inputs <- data_titanic[-k_fold_list[[i]],]
  test_inputs <- data_titanic[k_fold_list[[i]],]
  train_outputs <- data$survived[-k_fold_list[[i]]]
  test_outputs <- data$survived[k_fold_list[[i]]]

  # we define the pca dataset to use with the k-NN, SVM and Naive Bayes classifiers
  pca_train_inputs <- pca_data_titanic[-k_fold_list[[i]],]
  pca_test_inputs <- pca_data_titanic[k_fold_list[[i]],]

  
  # 1) KNN
  # running the algorithm
  data.knn <- knn(pca_train_inputs, pca_test_inputs, train_outputs, k=11)
  # we create the confusion matrix
  confusion_knn <- table(data.knn, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  knn_acc <- sum(diag(confusion_knn))/sum(confusion_knn)
  knn_acc_vector <- c(knn_acc_vector, knn_acc)
  knn_auc <- auc(roc(test_outputs, as.numeric(data.knn)))
  knn_auc_vector <- c(knn_auc_vector, knn_auc)
  knn_rec <- confusion_knn[2,2]/(confusion_knn[2,2]+confusion_knn[1,2])
  knn_rec_vector <- c(knn_rec_vector, knn_rec)
  knn_pre <- confusion_knn[2,2]/(confusion_knn[2,2]+confusion_knn[2,1])
  knn_pre_vector <- c(knn_pre_vector, knn_pre)
  mean_knn_acc <- round(mean(knn_acc_vector),4)
  mean_knn_auc <- round(mean(knn_auc_vector),4)
  mean_knn_rec <- round(mean(knn_rec_vector),4)
  mean_knn_pre <- round(mean(knn_pre_vector),4)
  
  
  # 2) ANN
  data.ann <- neuralnet(train_outputs ~ ., train_inputs, hidden = c(1,1))
  predictions_ann <- predict(data.ann, test_inputs)
  predicted_classes_ann <- round(predictions_ann[,1])
  predicted_classes_ann <- as.matrix(predicted_classes_ann)
  confusion_ann <- table(predicted_classes_ann, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  ann_acc <- sum(diag(confusion_ann))/sum(confusion_ann)
  ann_acc_vector <- c(ann_acc_vector, ann_acc)
  ann_auc <- auc(roc(test_outputs, as.vector(predicted_classes_ann)))
  ann_auc_vector <- c(ann_auc_vector, ann_auc)
  ann_rec <- confusion_ann[2,2]/(confusion_ann[2,2]+confusion_ann[1,2])
  ann_rec_vector <- c(ann_rec_vector, ann_rec)
  ann_pre <- confusion_ann[2,2]/(confusion_ann[2,2]+confusion_ann[2,1])
  ann_pre_vector <- c(ann_pre_vector, ann_pre)
  mean_ann_acc <- round(mean(ann_acc_vector),4)
  mean_ann_auc <- round(mean(ann_auc_vector),4)
  mean_ann_rec <- round(mean(ann_rec_vector),4)
  mean_ann_pre <- round(mean(ann_pre_vector),4)
  
  
  # 3) Support Vector Machines
  data.svm <- svm(train_outputs ~ ., data=pca_train_inputs)
  predictions_svm <- predict(data.svm, pca_test_inputs)
  predicted_classes_svm <- round(predictions_svm)
  confusion_svm <- table(predicted_classes_svm, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  svm_acc <- sum(diag(confusion_svm))/sum(confusion_svm)
  svm_acc_vector <- c(svm_acc_vector, svm_acc)
  svm_auc <- auc(roc(test_outputs, as.vector(predicted_classes_svm)))
  svm_auc_vector <- c(svm_auc_vector, svm_auc)
  svm_rec <- confusion_svm[2,2]/(confusion_svm[2,2]+confusion_svm[1,2])
  svm_rec_vector <- c(svm_rec_vector, svm_rec)
  svm_pre <- confusion_svm[2,2]/(confusion_svm[2,2]+confusion_svm[2,1])
  svm_pre_vector <- c(svm_pre_vector, svm_pre)
  mean_svm_acc <- round(mean(svm_acc_vector),4)
  mean_svm_auc <- round(mean(svm_auc_vector),4)
  mean_svm_rec <- round(mean(svm_rec_vector),4)
  mean_svm_pre <- round(mean(svm_pre_vector),4)
  
  
  # 4) Random Forests
  data.rf <- randomForest(train_outputs ~ ., train_inputs)
  predictions_rf <- predict(data.rf, test_inputs)
  predicted_classes_rf <- round(predictions_rf)
  confusion_rf <- table(predicted_classes_rf, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  rf_acc <- sum(diag(confusion_rf))/sum(confusion_rf)
  rf_acc_vector <- c(rf_acc_vector, rf_acc)
  rf_auc <- auc(roc(test_outputs, as.vector(predicted_classes_rf)))
  rf_auc_vector <- c(rf_auc_vector, rf_auc)
  rf_rec <- confusion_rf[2,2]/(confusion_rf[2,2]+confusion_rf[1,2])
  rf_rec_vector <- c(rf_rec_vector, rf_rec)
  rf_pre <- confusion_rf[2,2]/(confusion_rf[2,2]+confusion_rf[2,1])
  rf_pre_vector <- c(rf_pre_vector, rf_pre)
  mean_rf_acc <- round(mean(rf_acc_vector),4)
  mean_rf_auc <- round(mean(rf_auc_vector),4)
  mean_rf_rec <- round(mean(rf_rec_vector),4)
  mean_rf_pre <- round(mean(rf_pre_vector),4)
  
  # 5) Naive Bayes classifier
  data.nbayes <- naiveBayes(y=train_outputs, x=pca_train_inputs, laplace=0.1)
  predictions_nbayes <- predict(data.nbayes, newdata=pca_test_inputs, type='class')
  confusion_nbayes <- table(predictions_nbayes, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  nbayes_acc <- sum(diag(confusion_nbayes))/sum(confusion_nbayes)
  nbayes_acc_vector <- c(nbayes_acc_vector, nbayes_acc)
  nbayes_auc <- auc(roc(test_outputs, as.numeric(predictions_nbayes)))
  nbayes_auc_vector <- c(nbayes_auc_vector, nbayes_auc)
  nbayes_rec <- confusion_nbayes[2,2]/(confusion_nbayes[2,2]+confusion_nbayes[1,2])
  nbayes_rec_vector <- c(nbayes_rec_vector, nbayes_rec)
  nbayes_pre <- confusion_nbayes[2,2]/(confusion_nbayes[2,2]+confusion_nbayes[2,1])
  nbayes_pre_vector <- c(nbayes_pre_vector, nbayes_pre)
  mean_nbayes_acc <- round(mean(nbayes_acc_vector),4)
  mean_nbayes_auc <- round(mean(nbayes_auc_vector),4)
  mean_nbayes_rec <- round(mean(nbayes_rec_vector),4)
  mean_nbayes_pre <- round(mean(nbayes_pre_vector),4)
  
  # 6) Decision Tree
  data.dtree <- rpart(train_outputs ~ ., data=as.data.frame(train_inputs))
  predictions_dtree <- predict(data.dtree, as.data.frame(test_inputs))
  predicted_classes_dtree <- round(predictions_dtree)
  confusion_dtree <- table(predicted_classes_dtree, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  dtree_acc <- sum(diag(confusion_dtree))/sum(confusion_dtree)
  dtree_acc_vector <- c(dtree_acc_vector, dtree_acc)
  dtree_auc <- auc(roc(test_outputs, as.numeric(predicted_classes_dtree)))
  dtree_auc_vector <- c(dtree_auc_vector, dtree_auc)
  dtree_rec <- confusion_dtree[2,2]/(confusion_dtree[2,2]+confusion_dtree[1,2])
  dtree_rec_vector <- c(dtree_rec_vector, dtree_rec)
  dtree_pre <- confusion_dtree[2,2]/(confusion_dtree[2,2]+confusion_dtree[2,1])
  dtree_pre_vector <- c(dtree_pre_vector, dtree_pre)
  mean_dtree_acc <- round(mean(dtree_acc_vector),4)
  mean_dtree_auc <- round(mean(dtree_auc_vector),4)
  mean_dtree_rec <- round(mean(dtree_rec_vector),4)
  mean_dtree_pre <- round(mean(dtree_pre_vector),4)
  
  # 7) Logistic Regression
  data.logr <- glm(train_outputs ~ ., data=as.data.frame(cbind(train_inputs, train_outputs)), 
                   family = binomial(link='logit'))
  predictions_logr <- predict(data.logr, newdata=as.data.frame(test_inputs), 
                              type='response')
  predicted_classes_logr <- round(predictions_logr)
  confusion_logr <- table(predicted_classes_logr, test_outputs)
  # we calculate the accuracy, AUC score, precision, recall
  logr_acc <- sum(diag(confusion_logr))/sum(confusion_logr)
  logr_acc_vector <- c(logr_acc_vector, logr_acc)
  logr_auc <- auc(roc(test_outputs, as.numeric(predicted_classes_logr)))
  logr_auc_vector <- c(logr_auc_vector, logr_auc)
  logr_rec <- confusion_logr[2,2]/(confusion_logr[2,2]+confusion_logr[1,2])
  logr_rec_vector <- c(dtree_rec_vector, dtree_rec)
  logr_pre <- confusion_logr[2,2]/(confusion_logr[2,2]+confusion_logr[2,1])
  logr_pre_vector <- c(logr_pre_vector, logr_pre)
  mean_logr_acc <- round(mean(logr_acc_vector),4)
  mean_logr_auc <- round(mean(logr_auc_vector),4)
  mean_logr_rec <- round(mean(logr_rec_vector),4)
  mean_logr_pre <- round(mean(logr_pre_vector),4)
  
}
})


# SYNOPSIS
model_names <- c('K-NN','Neural Network', 'SVM', 'Random Forest', 
                 'Naive Bayes', 'Decision Tree', 'Logistic Regression')
# Creation of the 'Accuracy table'
model_accuracy_perc <- round(100*c(mean_knn_acc, mean_ann_acc, mean_svm_acc, mean_rf_acc, 
                                   mean_nbayes_acc, mean_dtree_acc, mean_logr_acc),2)
result_acc <- data.frame(Algorithm=model_names, Accuracy=model_accuracy_perc, row.names = NULL)
result_acc <- result_acc[order(result_acc$Accuracy, decreasing=TRUE),]
colnames(result_acc) <- c('Algorithm', 'Accuracy %')
print(result_acc, row.names=FALSE)
cat('\n\n')
# Creation of the 'AUC score table'
model_auc_perc <- round(100*c(mean_knn_auc, mean_ann_auc, mean_svm_auc, mean_rf_auc, 
                              mean_nbayes_auc, mean_dtree_auc, mean_logr_auc),2)
result_auc <- data.frame(Algorithm=model_names, AUC_score=model_auc_perc, row.names = NULL)
result_auc <- result_auc[order(result_auc$AUC_score, decreasing=TRUE),]
print(result_auc, row.names=FALSE)
cat('\n\n')
# Creation of the 'Recall (Sensitivity) table'
model_rec_perc <- round(100*c(mean_knn_rec, mean_ann_rec, mean_svm_rec, mean_rf_rec, 
                              mean_nbayes_rec, mean_dtree_rec, mean_logr_rec),2)
result_rec <- data.frame(Algorithm=model_names, Recall=model_rec_perc, row.names = NULL)
result_rec <- result_rec[order(result_rec$Recall, decreasing=TRUE),]
print(result_rec, row.names=FALSE)
cat('\n\n')
# Creation of the 'Precision table'
model_pre_perc <- round(100*c(mean_knn_pre, mean_ann_pre, mean_svm_pre, mean_rf_pre, 
                              mean_nbayes_pre, mean_dtree_pre, mean_logr_pre),2)
result_pre <- data.frame(Algorithm=model_names, Precision=model_pre_perc, row.names = NULL)
result_pre <- result_pre[order(result_pre$Precision, decreasing=TRUE),]
print(result_pre, row.names=FALSE)
cat('\n\n')
# Creation of the 'f1-score table'
knn_f1 <- 2*mean_knn_pre*mean_knn_rec/(mean_knn_pre + mean_knn_rec)
ann_f1 <- 2*mean_ann_pre*mean_ann_rec/(mean_ann_pre + mean_ann_rec)
svm_f1 <- 2*mean_svm_pre*mean_svm_rec/(mean_svm_pre + mean_svm_rec)
rf_f1 <- 2*mean_rf_pre*mean_rf_rec/(mean_rf_pre + mean_rf_rec)
nbayes_f1 <- 2*mean_nbayes_pre*mean_nbayes_rec/(mean_nbayes_pre + mean_nbayes_rec)
dtree_f1 <- 2*mean_dtree_pre*mean_dtree_rec/(mean_dtree_pre + mean_dtree_rec)
logr_f1 <- 2*mean_logr_pre*mean_logr_rec/(mean_logr_pre + mean_logr_rec)

model_f1_perc <- round(100*c(knn_f1, ann_f1, svm_f1, rf_f1, 
                             nbayes_f1, dtree_f1, logr_f1),2)
result_f1 <- data.frame(Algorithm=model_names, F1_score=model_f1_perc, row.names = NULL)
result_f1 <- result_f1[order(result_f1$F1_score, decreasing=TRUE),]
print(result_f1, row.names=FALSE)
cat('\n')


# CONCLUSION
# Which measure should we take into account to make our choice for the most suitable
# classifier?
# The answer is: "It depends".
# There are a number of factors that we need to keep in mind when choosing a classifier.
# These are: - Balanced vs imbalanced datasets, cost of false positives and false negatives,
# transparency, interpretability, computational efficiency, business or domain requirements etc.
# In our specific case, the "Titanic dataset" and the prediction of a passenger being alive 
# or deceased, if we were back in 1912 and were about to give an estimation to the passengers'
# relatives or friends that asked for a probability of their loved ones being alive, we would 
# choose Precision.
# Precision is the ratio of true positives (correctly predicted "alive") to the sum of true 
# positives and false positives (incorrectly predicted "alive"). High precision ensures that 
# when we predict someone as alive, there is a high probability that the prediction is correct. 
# This is crucial because telling someone that their loved one is alive when they are not would 
# be particularly distressing and misleading.
# In our run of the code the results for Precision were:
# 1) Neural Network (82.24%)
# 2) SVM (79.30%)
# 3) K-NN (78.24%)
# 4) Random Forest (77.89%)
# 5) Decision Tree (77.65%)
# 6) Logistic Regression (73.57%)
# 7) Naive Bayes (70.00%)
# So we would choose the Artificial Neural Network classifier. Even though it did not have the
# best overall accuracy, it showed the best precision (in our specific run of the code) which
# is the most suited measure in our case.