/*
 * Wrapper around C runtime functions in <time.h>, to allow larger values for the year part of a date/time
 * 
 * Microsoft C runtime library limits the year value to a maximum of 3000 (on x64 systems), but ASN.1 type
 * GeneralizedTime allows larger values.
 * 
 * Licensed under the BSD 3-clause license:
 *      https://opensource.org/licenses/BSD-3-Clause
 * 
 * Includes modified public domain source code from StackOverflow:
 *      https://stackoverflow.com/questions/7960318/math-to-convert-seconds-since-1970-into-date-and-vice-versa
 */

#include <stdbool.h>
#include <stdint.h>
#include <time.h>
#include "extended_datetime.h"

static int_fast64_t epoch_days_from_civil(int_fast64_t y, unsigned m, unsigned d)
{
    y -= m <= 2;
    const int_fast64_t era = (y >= 0 ? y : y-399) / 400;
    const unsigned yoe = (unsigned)(y - era * 400);                 // [0, 399]
    const unsigned doy = (153*(m + (m > 2 ? -3 : 9)) + 2)/5 + d-1;  // [0, 365]
    const unsigned doe = yoe * 365 + yoe/4 - yoe/100 + doy;         // [0, 146096]
    return era * 146097 + (int_fast64_t)doe - 719468;
}

static void civil_from_epoch_days(int_fast64_t z, struct tm *tm)
{
    z += 719468;

    const int_fast64_t era = (z >= 0 ? z : z - 146096) / 146097;
    const unsigned doe = (unsigned)(z - era * 146097);                      // [0, 146096]
    const unsigned yoe = (doe - doe/1460 + doe/36524 - doe/146096) / 365;   // [0, 399]
    const int_fast64_t y = (int_fast64_t)(yoe) + era * 400;
    const unsigned doy = doe - (365*yoe + yoe/4 - yoe/100);                 // [0, 365]
    const unsigned mp = (5*doy + 2)/153;                                    // [0, 11]
    const unsigned d = doy - (153*mp+2)/5 + 1;                              // [1, 31]
    const unsigned m = mp + (mp < 10 ? 3 : -9);                             // [1, 12]
    
    tm->tm_year = (int)(y  + (m <= 2) - 1900);
    tm->tm_mon = m - 1;
    tm->tm_mday =  d;
}

static unsigned weekday_from_epoch_days(gt_time_t z)
{
    return (unsigned)(z >= -4 ? (z+4) % 7 : (z+5) % 7 + 6);
}

static gt_time_t gt_epoch_adjustment(struct tm *save_tm)
{
    // save tm in case it was obtained from gmtime()/mktime() by the caller
    struct tm backup;
    
    if (save_tm)
        backup = *save_tm;

    time_t time_now = time(NULL);
    struct tm *tm = gmtime(&time_now);

    gt_time_t epoch_origin_adjust = 
        epoch_days_from_civil(tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday) * 24 * 3600 + tm->tm_hour * 3600 + tm->tm_min * 60 + tm->tm_sec
            -
        time_now;

    if (save_tm)
        *save_tm = backup;

    return epoch_origin_adjust;
}

static long gt_offset_from_GMT(struct tm arg)
{
    time_t specified_time = mktime(&arg);
    struct tm gmt_calendar_time = *gmtime(&specified_time);
    
    return specified_time - mktime(&gmt_calendar_time) - 
            ((gmtime(&specified_time)->tm_isdst > 0 ? 1 : 0) - (gmt_calendar_time.tm_isdst > 0 ? 1 : 0)) * 3600;

}

extern gt_time_t gt_timegm(struct tm *tm)
{
    gt_time_t year = tm->tm_year + 1900 + tm->tm_mon / 12;
    unsigned month = tm->tm_mon % 12 + 1;

    gt_time_t
        secs_since_epoch = epoch_days_from_civil(year, month, 1) + (tm->tm_mday - 1) * 24 * 3600
                            + tm->tm_hour * 3600 + tm->tm_min * 60 + tm->tm_sec,
        days_since_epoch = secs_since_epoch;
    
    // Re-construct struct tm
    tm->tm_sec = days_since_epoch % 60;
    days_since_epoch /= 60;

    tm->tm_min = days_since_epoch % 60;
    days_since_epoch /= 60;

    tm->tm_hour = days_since_epoch % 24;
    days_since_epoch /= 24;

    civil_from_epoch_days(days_since_epoch, tm);

    tm->tm_wday = weekday_from_epoch_days(days_since_epoch);

    bool is_leap_year;

    if (tm->tm_year % 4 == 0)
        if (tm->tm_year % 100 == 0)
            if (tm->tm_year % 400 == 0)
                is_leap_year = true;
            else
                is_leap_year = false;
        else
            is_leap_year = true;
    else
        is_leap_year = false;
    
    static const unsigned year_days_before_month[12] = { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 };

    if (is_leap_year || tm->tm_mon <= 1)
        tm->tm_yday = year_days_before_month[12] + tm->tm_mday;
    else
        tm->tm_yday = year_days_before_month[12] + tm->tm_mday - 1;

    tm->tm_yday--;       // struct tm counts day-of-year from 0

    tm->tm_isdst = 0;

    secs_since_epoch -= gt_epoch_adjustment(tm);

    return secs_since_epoch;
}

extern gt_time_t gt_time(gt_time_t *arg)
{
    time_t time_now;

    time(&time_now);

    if (arg)
        *arg = time_now;

    return time_now;
}

extern struct tm *gt_gmtime(const gt_time_t *timeptr)
{
    time_t time_now = time(NULL);
    struct tm *tm = gmtime(&time_now);
    gt_time_t days_since_epoch = *timeptr + gt_epoch_adjustment(NULL);

    // Re-construct struct tm
    tm->tm_sec = days_since_epoch % 60;
    days_since_epoch /= 60;

    tm->tm_min = days_since_epoch % 60;
    days_since_epoch /= 60;

    tm->tm_hour = days_since_epoch % 24;
    days_since_epoch /= 24;

    civil_from_epoch_days(days_since_epoch, tm);

    tm->tm_wday = weekday_from_epoch_days(days_since_epoch);

    bool is_leap_year;

    if (tm->tm_year % 4 == 0)
        if (tm->tm_year % 100 == 0)
            if (tm->tm_year % 400 == 0)
                is_leap_year = true;
            else
                is_leap_year = false;
        else
            is_leap_year = true;
    else
        is_leap_year = false;
    
    static const unsigned year_days_before_month[12] = { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 };

    if (is_leap_year || tm->tm_mon <= 1)
        tm->tm_yday = year_days_before_month[12] + tm->tm_mday;
    else
        tm->tm_yday = year_days_before_month[12] + tm->tm_mday - 1;

    tm->tm_yday--;       // struct tm counts day-of-year from 0

    tm->tm_isdst = 0;

    return tm;
}

extern struct tm *gt_localtime(gt_time_t *time);
extern gt_time_t gt_mktime(struct tm *tm);
