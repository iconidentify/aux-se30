/*
 * test_aap.c - unit tests for the AAP pure helpers (aap.c).
 * Builds and runs on the host:  cc -I../src test_aap.c ../src/aap.c -o test_aap
 * (the Makefile target `make test` does this and runs it).
 */
#include <stdio.h>
#include <string.h>
#include "aap.h"

static int tests = 0;
static int fails = 0;

#define CHECK(cond) do {                                                \
        tests++;                                                        \
        if (!(cond)) {                                                  \
            fails++;                                                    \
            printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);      \
        }                                                               \
    } while (0)

static void test_reqline(void)
{
    char m[8], p[256];

    CHECK(aap_parse_reqline("GET /file/x HTTP/1.0", m, sizeof m, p, sizeof p));
    CHECK(strcmp(m, "GET") == 0);
    CHECK(strcmp(p, "/file/x") == 0);

    CHECK(aap_parse_reqline("POST /exec HTTP/1.1\r\n", m, sizeof m, p, sizeof p));
    CHECK(strcmp(m, "POST") == 0);
    CHECK(strcmp(p, "/exec") == 0);

    /* malformed: no path */
    CHECK(aap_parse_reqline("GET", m, sizeof m, p, sizeof p) == 0);
    CHECK(aap_parse_reqline("", m, sizeof m, p, sizeof p) == 0);

    /* method longer than buffer is truncated, still parses path */
    CHECK(aap_parse_reqline("DELETE /a HTTP/1.0", m, 4, p, sizeof p));
    CHECK(strcmp(m, "DEL") == 0);
    CHECK(strcmp(p, "/a") == 0);
}

static void test_headers(void)
{
    const char *h =
        "Host: 10.1.1.20\r\n"
        "Content-Length: 1234\r\n"
        "X-Aap-Token:  sekret \r\n"
        "X-Exit-Code:-5\r\n";
    char v[64];

    CHECK(aap_header_long(h, "Content-Length", -1) == 1234);
    CHECK(aap_header_long(h, "content-length", -1) == 1234); /* case-insens */
    CHECK(aap_header_long(h, "Missing", 42) == 42);
    CHECK(aap_header_long(h, "X-Exit-Code", 0) == -5);

    CHECK(aap_header_str(h, "X-Aap-Token", v, sizeof v));
    CHECK(strcmp(v, "sekret") == 0);            /* trimmed both sides */
    CHECK(aap_header_str(h, "Host", v, sizeof v));
    CHECK(strcmp(v, "10.1.1.20") == 0);
    CHECK(aap_header_str(h, "Nope", v, sizeof v) == 0);

    /* a header name that is a prefix of another must not false-match */
    CHECK(aap_header_long(h, "Content", -7) == -7);
}

static void test_url_decode(void)
{
    char o[256];

    aap_url_decode("/file/usr/local/x", o, sizeof o);
    CHECK(strcmp(o, "/file/usr/local/x") == 0);

    aap_url_decode("a%20b%2Fc", o, sizeof o);
    CHECK(strcmp(o, "a b/c") == 0);

    aap_url_decode("x+y", o, sizeof o);
    CHECK(strcmp(o, "x y") == 0);

    /* stray percent left literal */
    aap_url_decode("100%done", o, sizeof o);
    CHECK(strcmp(o, "100%done") == 0);
}

static void test_header_end(void)
{
    CHECK(aap_header_end("GET / HTTP/1.0\r\n\r\nBODY", 22) == 18);
    CHECK(aap_header_end("A\n\nB", 4) == 3);          /* bare LF form */
    CHECK(aap_header_end("no terminator yet", 17) == -1);
}

static void test_crc32(void)
{
    /* IEEE 802.3 known-answer vectors */
    CHECK(aap_crc32((const unsigned char *) "123456789", 9) == 0xCBF43926UL);
    CHECK(aap_crc32((const unsigned char *) "", 0) == 0x00000000UL);
    CHECK(aap_crc32((const unsigned char *) "a", 1) == 0xE8B7BE43UL);
}

int main(void)
{
    test_reqline();
    test_headers();
    test_url_decode();
    test_header_end();
    test_crc32();

    printf("%d tests, %d failures\n", tests, fails);
    return fails ? 1 : 0;
}
