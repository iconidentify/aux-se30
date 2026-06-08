/*
 * aap.h - A/UX Agent Protocol: pure helpers (no I/O).
 *
 * These functions contain all the parsing / encoding logic so they can be
 * unit-tested on a modern host while the agent itself runs on A/UX.
 * Written in portable C89 so it compiles with both gcc 2.7.2.3 (A/UX) and a
 * modern host compiler.
 */
#ifndef AAP_H
#define AAP_H

#define AAP_VERSION "1.0"

/*
 * Parse an HTTP request line of the form  "GET /path HTTP/1.0".
 * Writes the method into <method> (capacity msz) and the request-target into
 * <path> (capacity psz), both NUL-terminated and truncated to fit.
 * Returns 1 on success, 0 if the line is malformed.
 */
int aap_parse_reqline(const char *line, char *method, int msz,
                      char *path, int psz);

/*
 * Look up header <name> (case-insensitive) in a raw header block <headers>
 * (the text between the request line and the blank line, lines CRLF- or
 * LF-separated). Copies the value (trimmed) into <out> (capacity osz).
 * Returns 1 if found, 0 otherwise.
 */
int aap_header_str(const char *headers, const char *name, char *out, int osz);

/*
 * Like aap_header_str but returns the value parsed as a long, or <dflt> if the
 * header is absent or non-numeric.
 */
long aap_header_long(const char *headers, const char *name, long dflt);

/*
 * URL-decode <in> (%XX escapes and '+' -> space) into <out> (capacity osz).
 * Always NUL-terminates. Returns the number of bytes written (excluding NUL).
 */
int aap_url_decode(const char *in, char *out, int osz);

/*
 * Find the end of the HTTP header section within the first <len> bytes of
 * <buf>, i.e. the offset just past the blank line ("\r\n\r\n" or "\n\n").
 * Returns the body offset, or -1 if no header terminator is present yet.
 */
int aap_header_end(const char *buf, int len);

/*
 * CRC-32 (IEEE 802.3, the zlib/PNG polynomial) over <len> bytes of <data>.
 * Used as an integrity check on transferred files. Known answer:
 *   aap_crc32("123456789", 9) == 0xCBF43926.
 */
unsigned long aap_crc32(const unsigned char *data, long len);

#endif /* AAP_H */
