## Overview ##

The OATH Token iPhone app automatically configures the iPhone to direct **oathtoken://** URLs to the OATH Token application. When the OATH Token app receives such an URL, for example because the user clicked on a hyperlink in a web page or email, it will prompt the user for a confirmation and then add the token to that user's token list.

This provides a simple mechanism for web-based provisioning of tokens. However, it is critical that the hyperlink be delivered **securely** to the user (e.g., via an encrypted and password-protected web page) so that the token's secret key is not revealed.

Note that with an appropriate QR code scanner app you can install tokens via QR Codes.This means you can deliver the token securely on a printed page, which can then be destroyed. The app must be able to recognize the QR Code as an URL and be able to open it, instead of just copying it as plain text. One app that has been successfully tested is [Qrafter](http://itunes.apple.com/us/app/qrafter-qr-code-reader/id416098700?mt=8).

## URL Format ##

This URL has a simple format: `oathtoken:///addToken?`_name1_`=`_value1_`&`_name2_`=`_value2_`&`...

The token to be added is configured using URL parameters as follows:

| **URL parameter** | **Required?** | **Default** | **Description** |
|:------------------|:--------------|:------------|:----------------|
| `name`            | Yes           | N/A         | Token display name (must not be empty) |
| `key`             | Yes           | N/A         | Hexadecimal key (at least eight bytes long) |
| `timeBased`       | No            | false       | Whether to create an event-based (**false**) or time-based (**true**) token |
| `counter`         | No            | 0           | Initial counter value (event-based tokens only) |
| `interval`        | No            | 30          | Timer interval length in seconds (time-based tokens only) |
| `displayHex`      | No            | false       | Whether to display token values in hexadecimal instead of decimal |
| `numDigits`       | No            | 6           | Number of digits to display (at least 4 and at most 10 (decimal) or 8 (hex)) |
| `lockdown`        | No            | false       | Whether to allow (**false**) or permanently disable (**true**) editing of the new token |

## Examples ##

### Example #1 ###

`oathtoken:///addToken?name=Web%20Token%20%231&key=0123456789abcdef555555`

Create a new event-based token named `Web Token #1' with key `0123456789abcdef555555`, initial counter value of zero, displaying six decimal digits. The user will be allowed to edit the token.

### Example #2 ###

`oathtoken:///addToken?name=Web%20Token%20%232&key=acbd18db4cc2f85cedef654fccc4a4d8&timeBased=true&interval=60&numDigits=10&lockdown=true`

Create a new time-based token named `Web Token #2' with key `acbd18db4cc2f85cedef654fccc4a4d8`, displaying 10 decimal digits based on a 60 second interval. The user will not be allowed to edit the token.

### Example #3 ###

The token in Example #1 could also be installed by scanning this QR code:

![http://oathtoken.googlecode.com/svn/wiki/qrcode.png](http://oathtoken.googlecode.com/svn/wiki/qrcode.png)

### Generator Program ###

Here's a little C program that generates these URLs from the command line.

```
#include <sys/types.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <pwd.h>
#include <err.h>

static void print_key(FILE *fp, const char *key, u_int len);
static void usage(void);

#define DEFAULT_COUNTER         0
#define DEFAULT_KEYLEN          16
#define DEFAULT_NUM_DIGITS      6
#define DEFAULT_INTERVAL        30
#define DEFAULT_NAME            "Security Token"

#define RANDOM_FILE             "/dev/urandom"

int
main(int argc, char **argv)
{
    const char *name = DEFAULT_NAME;
    unsigned int interval = DEFAULT_INTERVAL;
    unsigned int counter = DEFAULT_COUNTER;
    unsigned int num_digits = 6;
    int time_based = 1;
    int lock_down = 1;
    int hex_digits = 0;
    char *key = NULL;
    int keylen = DEFAULT_KEYLEN;
    FILE *fp;
    int i, j;
    unsigned int b;

    // Parse command line
    while ((i = getopt(argc, argv, "c:d:Ii:k:Nn:x")) != -1) {
        switch (i) {
        case 'c':
            counter = atoi(optarg);
            break;
        case 'd':
            num_digits = atoi(optarg);
            break;
        case 'I':
            time_based = 0;
            break;
        case 'i':
            interval = atoi(optarg);
            break;
        case 'k':
            if (strlen(optarg) % 2 != 0)
                errx(1, "invalid hex key `%s': odd number of digits", optarg);
            if ((key = malloc((keylen = strlen(optarg) / 2))) == NULL)
                err(1, "malloc");
            for (j = 0; j < keylen; j++) {
                if (sscanf(optarg + 2 * j, "%2x", &b) != 1)
                    errx(1, "invalid hex key `%s': can't parse", optarg);
                key[j] = b & 0xff;
            }
            break;
        case 'n':
            name = optarg;
            break;
        case 'N':
            lock_down = 0;
            break;
        case 'x':
            hex_digits = 1;
            break;
        case '?':
        default:
            usage();
            exit(1);
        }
    }
    argv += optind;
    argc -= optind;
    switch (argc) {
    case 0:
        break;
    default:
        usage();
        exit(1);
    }

    // Generate key
    if (key == NULL) {
        if ((key = malloc((keylen = DEFAULT_KEYLEN))) == NULL)
            err(1, "malloc");
        if ((fp = fopen(RANDOM_FILE, "r")) == NULL)
            err(1, "%s", RANDOM_FILE);
        if (fread(key, 1, keylen, fp) != keylen)
            err(1, "%s", RANDOM_FILE);
        fclose(fp);
        fprintf(stderr, "generated key: ");
        print_key(stderr, key, keylen);
        fprintf(stderr, "\n");
    }

    // Output URL
    printf("oathtoken:///addToken?name=");
    for (i = 0; name[i] != '\0'; i++) {
        if (isalnum(name[i]))
            printf("%c", name[i]);
        else
            printf("%%%02x", name[i] & 0xff);
    }
    printf("&key=");
    print_key(stdout, key, keylen);
    if (time_based)
        printf("&timeBased=true");
    if (!time_based && counter != DEFAULT_COUNTER)
        printf("&counter=%u", counter);
    if (time_based && interval != DEFAULT_INTERVAL)
        printf("&interval=%u", interval);
    if (num_digits != DEFAULT_NUM_DIGITS)
        printf("&numDigits=%u", num_digits);
    if (hex_digits)
        printf("&displayHex=true");
    if (lock_down)
        printf("&lockdown=true");
    printf("\n");

    // Done
    return 0;
}

static void
print_key(FILE *fp, const char *key, u_int len)
{
    int i;

    for (i = 0; i < len; i++)
        fprintf(fp, "%02x", key[i] & 0xff);
}

static void
usage(void)
{
    fprintf(stderr, "Usage: genotpurl [-INx] [-n name] [-c counter] [-d num-digits] [-i interval] [-k key]\n");
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -c\tInitial counter value (default %d)\n", DEFAULT_COUNTER);
    fprintf(stderr, "  -d\tNumber of digits (default %d)\n", DEFAULT_NUM_DIGITS);
    fprintf(stderr, "  -I\tInterval-based instead of time-based\n");
    fprintf(stderr, "  -i\tTime interval in seconds (default %d)\n", DEFAULT_INTERVAL);
    fprintf(stderr, "  -k\tSpecify hex key (otherwise, auto-generate)\n");
    fprintf(stderr, "  -N\tDon't lock down\n");
    fprintf(stderr, "  -n\tSpecify name for token (default \"%s\")\n", DEFAULT_NAME);
    fprintf(stderr, "  -x\tHex digits insteda of decimal\n");
}
```