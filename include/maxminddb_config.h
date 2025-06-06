/* include/maxminddb_config.h.  Generated from maxminddb_config.h.in by configure.  */
#ifndef MAXMINDDB_CONFIG_H
#define MAXMINDDB_CONFIG_H

#ifndef MMDB_UINT128_USING_MODE
/* Define as 1 if we we use unsigned int __atribute__ ((__mode__(TI))) for uint128 values */
#define MMDB_UINT128_USING_MODE 0
#endif

#ifndef MMDB_UINT128_IS_BYTE_ARRAY
/* Define as 1 if we don't have an unsigned __int128 type */
#define MMDB_UINT128_IS_BYTE_ARRAY 0
#endif

#endif                          /* MAXMINDDB_CONFIG_H */
#undef MMDB_UINT128_USING_MODE
#undef MMDB_UINT128_IS_BYTE_ARRAY
#define MMDB_UINT128_USING_MODE 0
#define MMDB_UINT128_IS_BYTE_ARRAY 1
