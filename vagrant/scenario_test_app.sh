
echo "export JAVA_HOME=/opt/java_jdk" > /etc/profile.d/app.sh
source /etc/profile.d/app.sh
#export JAVA_HOME=/usr/java/jdk1.8.0_162
#export JRE_HOME=/usr/java/jdk1.8.0_162/jre
#export MAVEN_HOME=/usr/local/apache-maven-3.5.2
#export PATH=$JAVA_HOME"/bin":$MAVEN_HOME"/bin":$PATH 
#Check Architecture
#do_java() {
#if [[ "$CPUINFO" == x86_64 ]]; then
#do_x86
#fi
#}