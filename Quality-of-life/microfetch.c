#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <stdlib.h>

#define MAX_LEN 256

#define RESET   "\033[0m"
#define GREEN   "\033[32m"
#define CYAN    "\033[36m"
#define YELLOW  "\033[33m"

typedef struct {
    int show_colors;
    int minimal_mode;
    int fixed_width;  // 0 = auto, >0 = fixed width
} Config;

void get_os_info(char* os_name, size_t len) {
    FILE* fp = fopen("/etc/os-release", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "PRETTY_NAME=")) {
                char* start = strchr(line, '"');
                if (start) {
                    char* end = strchr(start + 1, '"');
                    if (end) {
                        *end = '\0';
                        strncpy(os_name, start + 1, len - 1);
                        fclose(fp);
                        return;
                    }
                }
            }
        }
        fclose(fp);
    }
    strncpy(os_name, "Unknown", len);
}

void get_cpu_info(char* cpu_info, size_t len) {
    FILE* fp = fopen("/proc/cpuinfo", "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            if (strstr(line, "model name")) {
                char* colon = strchr(line, ':');
                if (colon) {
                    colon += 2;
                    char* nl = strchr(colon, '\n');
                    if (nl) *nl = '\0';
                    
                    char* at_pos = strstr(colon, " @ ");
                    if (at_pos) {
                        *at_pos = '\0';  // Truncate at frequency
                    }
                    
                    if (strlen(colon) > 35) {
                        strncpy(cpu_info, colon, 32);
                        strcat(cpu_info, "...");
                    } else {
                        strncpy(cpu_info, colon, len - 1);
                    }
                    fclose(fp);
                    return;
                }
            }
        }
        fclose(fp);
    }
    strncpy(cpu_info, "Unknown", len);
}

void get_memory_info(char* mem_info, size_t len) {
    struct sysinfo info;
    if (sysinfo(&info) == 0) {
        unsigned long total_mb = info.totalram / (1024 * 1024);
        unsigned long free_mb = info.freeram / (1024 * 1024);
        unsigned long used_mb = total_mb - free_mb;
        int percent = (total_mb > 0) ? (used_mb * 100 / total_mb) : 0;
        snprintf(mem_info, len, "%luMB / %luMB (%d%%)", 
                 used_mb, total_mb, percent);
    } else {
        strncpy(mem_info, "Unknown", len);
    }
}

void get_uptime(char* uptime_str, size_t len) {
    FILE* fp = fopen("/proc/uptime", "r");
    if (fp) {
        float uptime_seconds;
        fscanf(fp, "%f", &uptime_seconds);
        fclose(fp);
        
        int days = uptime_seconds / 86400;
        int hours = (uptime_seconds - days * 86400) / 3600;
        int minutes = (uptime_seconds - days * 86400 - hours * 3600) / 60;
        
        if (days > 0) {
            snprintf(uptime_str, len, "%dd %dh %dm", days, hours, minutes);
        } else if (hours > 0) {
            snprintf(uptime_str, len, "%dh %dm", hours, minutes);
        } else {
            snprintf(uptime_str, len, "%dm", minutes);
        }
    } else {
        strncpy(uptime_str, "Unknown", len);
    }
}

void get_kernel_version(char* kernel, size_t len) {
    struct utsname buf;
    if (uname(&buf) == 0) {
        snprintf(kernel, len, "%s %s", buf.sysname, buf.release);
    } else {
        strncpy(kernel, "Unknown", len);
    }
}

void display_simple_box(Config* config) {
    char os_name[MAX_LEN];
    char cpu_info[MAX_LEN];
    char mem_info[MAX_LEN];
    char uptime[MAX_LEN];
    char kernel[MAX_LEN];
    char hostname[MAX_LEN];
    
    get_os_info(os_name, sizeof(os_name));
    get_cpu_info(cpu_info, sizeof(cpu_info));  
    get_memory_info(mem_info, sizeof(mem_info));
    get_uptime(uptime, sizeof(uptime));
    get_kernel_version(kernel, sizeof(kernel));
    gethostname(hostname, sizeof(hostname));
    
    char* username = getenv("USER");
    if (!username) username = "user";
    
    int width = 60;
    
    printf("\n");
    
    if (config->show_colors) printf(YELLOW);
    printf("╔");
    for (int i = 0; i < width - 2; i++) printf("═");
    printf("╗\n");
    if (config->show_colors) printf(RESET);
    
    char user_host[100];
    snprintf(user_host, sizeof(user_host), "%s@%s", username, hostname);
    int user_host_len = strlen(user_host);
    int padding = (width - 2 - user_host_len) / 2;
    
    if (config->show_colors) printf(YELLOW);
    printf("║");
    if (config->show_colors) printf(RESET);
    
    for (int i = 0; i < padding; i++) printf(" ");
    
    if (config->show_colors) printf(GREEN);
    printf("%s", user_host);
    if (config->show_colors) printf(RESET);
    
    for (int i = 0; i < padding + ((width - 2 - user_host_len) % 2); i++) printf(" ");
    
    if (config->show_colors) printf(YELLOW);
    printf("║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("╠");
    for (int i = 0; i < width - 2; i++) printf("═");
    printf("╣\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║");
    for (int i = 0; i < width - 2; i++) printf(" ");
    printf("║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║ ");
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(CYAN);
    printf("OS:");
    if (config->show_colors) printf(RESET);
    printf("      ");
    if (config->show_colors) printf(GREEN);
    printf("%-43s", os_name);
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(YELLOW);
    printf(" ║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║ ");
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(CYAN);
    printf("Kernel:");
    if (config->show_colors) printf(RESET);
    printf("  ");
    if (config->show_colors) printf(GREEN);
    printf("%-43s", kernel);
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(YELLOW);
    printf(" ║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║ ");
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(CYAN);
    printf("CPU:");
    if (config->show_colors) printf(RESET);
    printf("     ");
    if (config->show_colors) printf(GREEN);
    printf("%-43s", cpu_info);
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(YELLOW);
    printf(" ║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║ ");
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(CYAN);
    printf("Memory:");
    if (config->show_colors) printf(RESET);
    printf("  ");
    if (config->show_colors) printf(GREEN);
    printf("%-43s", mem_info);
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(YELLOW);
    printf(" ║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║ ");
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(CYAN);
    printf("Uptime:");
    if (config->show_colors) printf(RESET);
    printf("  ");
    if (config->show_colors) printf(GREEN);
    printf("%-43s", uptime);
    if (config->show_colors) printf(RESET);
    if (config->show_colors) printf(YELLOW);
    printf(" ║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("║");
    for (int i = 0; i < width - 2; i++) printf(" ");
    printf("║\n");
    if (config->show_colors) printf(RESET);
    
    if (config->show_colors) printf(YELLOW);
    printf("╚");
    for (int i = 0; i < width - 2; i++) printf("═");
    printf("╝\n");
    if (config->show_colors) printf(RESET);
    
    printf("\n");
}

void display_minimal(Config* config) {
    char os_name[MAX_LEN];
    char cpu_info[MAX_LEN];
    char mem_info[MAX_LEN];
    char uptime[MAX_LEN];
    char kernel[MAX_LEN];
    char hostname[MAX_LEN];
    
    get_os_info(os_name, sizeof(os_name));
    get_cpu_info(cpu_info, sizeof(cpu_info));
    get_memory_info(mem_info, sizeof(mem_info));
    get_uptime(uptime, sizeof(uptime));
    get_kernel_version(kernel, sizeof(kernel));
    gethostname(hostname, sizeof(hostname));
    
    char* username = getenv("USER");
    if (!username) username = "user";
    
    printf("\n");
    if (config->show_colors) printf(GREEN);
    printf("%s@%s\n", username, hostname);
    if (config->show_colors) printf(RESET);
    
    printf("OS:      %s\n", os_name);
    printf("Kernel:  %s\n", kernel);
    printf("CPU:     %s\n", cpu_info);
    printf("Memory:  %s\n", mem_info);
    printf("Uptime:  %s\n", uptime);
    printf("\n");
}

int main(int argc, char* argv[]) {
    Config config = {
        .show_colors = 1,
        .minimal_mode = 0,
        .fixed_width = 0
    };
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--minimal") == 0 || strcmp(argv[i], "-m") == 0) {
            config.minimal_mode = 1;
        } else if (strcmp(argv[i], "--no-color") == 0 || strcmp(argv[i], "-n") == 0) {
            config.show_colors = 0;
        } else if (strcmp(argv[i], "--simple") == 0 || strcmp(argv[i], "-s") == 0) {
            config.minimal_mode = 0;  // Use simple box
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf("MicroFetch - Lightweight system info for embedded systems\n");
            printf("Usage: %s [options]\n", argv[0]);
            printf("Options:\n");
            printf("  -m, --minimal    Minimal output (no ASCII art)\n");
            printf("  -s, --simple     Simple box layout (default)\n");
            printf("  -n, --no-color   Disable colored output\n");
            printf("  -h, --help       Show this help message\n");
            return 0;
        }
    }
    
    if (config.minimal_mode) {
        display_minimal(&config);
    } else {
        display_simple_box(&config);
    }
    
    return 0;
}
