#if !defined(_ASN1_CMAKE_MODULE_PATCH_EXTENDED_DATETIME)
#define _ASN1_CMAKE_MODULE_PATCH_EXTENDED_DATETIME

#include <stdint.h>

#if defined(__cplusplus)
extern "C"
{
#endif

typedef int_fast64_t gt_time_t;

/// get current system date and time as a UNIX time (seconds since the epoch)
/// see C standard time() function
extern gt_time_t gt_time(gt_time_t *arg);

/// convert from UNIX time (seconds since the epoch) to calendar time in GMT
/// see GNU extension function timegm()
extern gt_time_t gt_timegm(struct tm *tm);

/// convert calendar time in GMT to UNIX time (seconds since the epoch)
/// see standard gmtime() function
extern struct tm *gt_gmtime(const gt_time_t *timeptr);

/// convert from UNIX time (seconds since the epoch) to local calendar time
/// see standard localtime() function
extern struct tm *gt_localtime(gt_time_t *time);

/// convert local calendar time to UNIX time (seconds since the epoch)
/// see standard mktime() function
extern gt_time_t gt_mktime(struct tm *tm);

#if defined(__cplusplus)
}
#endif

#endif // _ASN1_CMAKE_MODULE_PATCH_EXTENDED_DATETIME
