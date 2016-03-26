# Replace unfinished macro definition
#
#    #define GMTOFF(tm) (-timezone)
#
# with a static fucntion:
#
#   long GMTOFF(struct tm *arg)
#   {
#       time_t specified_tiem = mktime(arg);
#       //...
#   }

if(ASN1_GENERATED_SOURCE STREQUAL "${ASN1_WORKING_DIRECTORY}/GeneralizedTime.c")
    set(ASN1_GENERALIZED_TIME_DEFINE "[\r\n]+[ \t\r\n]*#[ \t]*define[ \t]+GMTOFF\\([^)(\r\n]*\\)[ \t]+\\([ \t]*-[ \t]*timezone[ \t]*\\)[ \t]*[\r\n]+")
    if(ASN1_GENERATED_SOURCE_CONTENT MATCHES "${ASN1_GENERALIZED_TIME_DEFINE}")
        string(REGEX REPLACE "${ASN1_GENERALIZED_TIME_DEFINE}" "
static long GMTOFF(struct tm arg)
{
    time_t specified_time = mktime(&arg);
    struct tm gmt_calendar_time = *gmtime(&specified_time);
    
    return specified_time - mktime(&gmt_calendar_time) - 
            ((gmtime(&specified_time)->tm_isdst > 0 ? 1 : 0) - (gmt_calendar_time.tm_isdst > 0 ? 1 : 0)) * 3600;

}
"
                    ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
        set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
    endif()
endif()
