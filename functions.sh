# shell script functions to be loaded on your bashrc file 

# creates a file with BBRF stats 
# The output is in the form 
#  program1, #domains, #urls
# Input parameter: filename
getBBRFStats()
{   
    IFS=$'\n'
    filename=$1
    for value in $(bbrf programs --show-disabled);
        do 
            echo "Getting stats of program $value"
            numUrls=$(bbrf urls -p "$value" | wc -l)
            numDomains=$(bbrf domains -p "$value" | wc -l)
            echo -e "$value, $numDomains,  $numUrls" >> $filename
    done
}

# displays all the disabled programs in BBRF
getDisabledPrograms()
{
    for value in $(bbrf programs --show-disabled 2>/dev/null);
        do 
            disabled=$(bbrf show "$value" 2>/dev/null| jq '.disabled')
            if [ "$disabled" == "true" ] 
            then
                echo -e $value
            fi
    done
}
# This function allows to find the difference between to input/output files (containing domains or urls)
# Example if you ran bbrf urls multiple times and you want to output only the new urls
#1. bbrf urls > file1.txt
#some programs/urls were added 
#2. bbrf urls > file2.txt
#using the function we can output only the new added content to the file

#diffFiles file1.txt file2.txt output.txt
diffFiles()
{
    comm -3 <(sort $1) <(sort $2) > $3
}

# This function is used when adding a new program 
# it requires subfinder and assetfinder

getDomains()
{
    bbrf scope in --wildcard|bbrf inscope add -; 
    bbrf scope in --wildcard|bbrf domain add - --show-new; 
    bbrf scope in |bbrf domain add - --show-new; 
    bbrf scope in| subfinder -t 60 -silent |bbrf domain add - -s subfinder  --show-new; 
    bbrf scope in|assetfinder|bbrf domain add - -s assetfinder
}

# This function is used when adding a new program and after the getDomains function
# it requires httpx and httprobe
getUrls()
{
    RED="\e[31m"
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"

    #IFS=$'\n'
    doms=$(bbrf domains|grep -v DEBUG|tr ' ' '\n') 
    #echo $doms
    if [ ${#doms} -gt 0 ] 
        then
            echo -en "${RED} httpx domains${ENDCOLOR}\n"        
            echo "$doms" |httpx -silent -threads 100 |bbrf url add - -s httpx --show-new
            echo -en "${RED} httprobe domains${ENDCOLOR}\n"        
            echo "$doms" |httprobe -c 50 |bbrf url add - -s httprobe --show-new
    fi
}

#input platform/site
#Example  addPrograms intigriti 
addPrograms()
{
    RED="\e[31m"
    YELLOW="\e[33m"
    ENDCOLOR="\e[0m"

    if [ -z "$1" ]
    then
      echo "Use addPrograms platform (intrigrit, bugcrowd, h1, etc)"
      return 1;
    fi
    program=$1
    while true;
    do
        # Read the user input   
        site="$1"  
        echo -en "${YELLOW}Program name: ${ENDCOLOR}"  
        read program
        echo -en "${YELLOW}Reward? (1:money, 2:points, 3:thanks) ${ENDCOLOR} "
        read reward
        case $reward in
        1)    val="money";;
        2)    val="points";;
        3)    val="thanks";;
        esac
        echo -en "${YELLOW}Url?  ${ENDCOLOR} "
        read url

        bbrf new "$program" -t site:"$site" -t reward:"$val"  -t url:"$url"
        bbrf use "$program" 
    #echo -n "Creating $program in $site (default)"  
        echo ""
        IFS= read -r -p "$(echo -en $YELLOW" Add IN scope: "$ENDCOLOR)" wildcards
        #if empty skip
        if [ ! -z "$wildcards" ]
            then
                bbrf inscope add $wildcards 
            echo -n "Scope added \n"  

        else    
            echo -n "Empty!"
    fi         
    IFS= read -r -p "$(echo -en $YELLOW " Add OUT scope:" $ENDCOLOR)" oswildcards
    if [ ! -z "$oswildcards" ]
         then
             bbrf outscope add $oswildcards
             echo ""
             echo -ne "${YELLOW}out Scope added $oswildcards${ENDCOLOR}"  
         else
             echo -n "Empty!"
    fi
    echo ""
    echo -ne "${RED}Getting domains${ENDCOLOR}\n"; getdomains  
    echo -ne "${RED}Getting urls ${ENDCOLOR}\n"; geturls  
    #echo -ne "${YELLOW}continue? (y/n)${YELLOW}" 
    #read cont
    #if [ "$cont" == "n" ]; then
    #        echo "exiting"
    #        exit
    #else 
    #    echo "" #"not n "
    #fi
    done
} 
