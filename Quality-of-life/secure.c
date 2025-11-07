#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>

#define CMD_BUFFER 2048
#define NAME_BUFFER 512

double elapsed(clock_t start, clock_t end) {
    return ((double)(end - start)) / CLOCKS_PER_SEC;
}

int check_command(const char *cmd) {
    char command[CMD_BUFFER];
    snprintf(command, sizeof(command), "command -v %s >/dev/null 2>&1", cmd);
    return system(command) == 0;
}

void check_dependencies() {
    const char *deps[] = {"fzf", "gzip", "tar", "openssl"};
    int missing = 0;

    printf("🔍 Checking dependencies...\n");
    for (int i = 0; i < (int)(sizeof(deps)/sizeof(deps[0])); i++) {
        if (!check_command(deps[i])) {
            printf("❌ Missing: %s\n", deps[i]);
            missing = 1;
        } else {
            printf("✅ Found: %s\n", deps[i]);
        }
    }

    if (missing) {
        char choice[4];
        printf("\nSome dependencies are missing. Install them? [y/N]: ");
        if (!fgets(choice, sizeof(choice), stdin)) exit(1);
        if (choice[0] == 'y' || choice[0] == 'Y') {
            printf("\nInstalling dependencies (assuming pacman)...\n");
            system("sudo pacman -Sy --noconfirm fzf gzip tar openssl");
        } else {
            printf("Exiting. Please install missing packages manually.\n");
            exit(1);
        }
    }
}

int is_directory(const char *path) {
    struct stat st;
    if (stat(path, &st) != 0) {
        return 0;
    }
    return S_ISDIR(st.st_mode);
}

int main(void) {
    char selected[NAME_BUFFER];
    char password[NAME_BUFFER];
    char command[CMD_BUFFER];
    char base[NAME_BUFFER];
    clock_t start, end;

    check_dependencies();

    FILE *fp = popen("find . -maxdepth 1 \\( -type f -o -type d \\) | sed 's|^\\./||' | fzf", "r");
    if (!fp) {
        fprintf(stderr, "Error: fzf not found or failed to run.\n");
        return 1;
    }

    if (!fgets(selected, sizeof(selected), fp)) {
        fprintf(stderr, "No selection made.\n");
        pclose(fp);
        return 1;
    }
    pclose(fp);
    selected[strcspn(selected, "\n")] = '\0';

    start = clock();

    size_t len = strlen(selected);
    if (len > 0 && selected[len-1] == '/') {
        selected[len-1] = '\0';
    }

    snprintf(base, sizeof(base), "%s", selected);

    if (strstr(selected, ".enc")) {
        printf("Enter password to decrypt: ");
        if (!fgets(password, sizeof(password), stdin)) return 1;
        password[strcspn(password, "\n")] = '\0';

        char output[NAME_BUFFER];
        snprintf(output, sizeof(output), "%s", base);
        output[strlen(output)-4] = '\0'; // drop ".enc"

        printf("Decrypting and decompressing...\n");

        snprintf(command, sizeof(command),
                 "openssl enc -aes-256-cbc -d -pbkdf2 -in '%s' -out '%s.tar.gz' -pass pass:\"%s\" && "
                 "tar -xzf '%s.tar.gz' && rm -f '%s.tar.gz' '%s'",
                 selected, output, password, output, selected, selected);

        if (system(command) == 0) {
            printf("✅ Decryption & extraction successful: %s\n", output);
        } else {
            printf("❌ Decryption or extraction failed.\n");
        }

    } else {
        printf("Enter password to encrypt: ");
        if (!fgets(password, sizeof(password), stdin)) return 1;
        password[strcspn(password, "\n")] = '\0';

        printf("Compressing and encrypting...\n");

        if (is_directory(selected)) {
            snprintf(command, sizeof(command),
                     "tar -czf '%s.tar.gz' '%s' && "
                     "openssl enc -aes-256-cbc -pbkdf2 -in '%s.tar.gz' -out '%s.enc' -pass pass:\"%s\" && "
                     "rm -rf '%s' '%s.tar.gz'",
                     base, selected, base, base, password, selected, base);
        } else {
            snprintf(command, sizeof(command),
                     "gzip -c '%s' > '%s.gz' && "
                     "openssl enc -aes-256-cbc -pbkdf2 -in '%s.gz' -out '%s.enc' -pass pass:\"%s\" && "
                     "rm -f '%s' '%s.gz'",
                     selected, base, base, base, password, selected, base);
        }

        if (system(command) == 0) {
            printf("✅ Encryption successful: %s.enc\n", base);
        } else {
            printf("❌ Encryption failed.\n");
        }
    }

    end = clock();
    printf("⏳ Time elapsed: %.2f seconds\n", elapsed(start, end));

    return 0;
}

