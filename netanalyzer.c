#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pcap.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <time.h>

#define COLOR_RED "\x1b[31m"
#define COLOR_GREEN "\x1b[32m"
#define COLOR_YELLOW "\x1b[33m"
#define COLOR_BLUE "\x1b[34m"
#define COLOR_RESET "\x1b[0m"

// Statistics structure
typedef struct {
    unsigned long packet_count;
    unsigned long byte_count;
    unsigned long tcp_count;
    unsigned long udp_count;
    unsigned long http_count;
    unsigned long dns_count;
} stats_t;

stats_t stats = {0};

// Connection tracking structure
typedef struct connection {
    struct in_addr src_ip;
    struct in_addr dst_ip;
    uint16_t src_port;
    uint16_t dst_port;
    int protocol; // IPPROTO_TCP or IPPROTO_UDP
    char state[16]; // simple state representation
    struct connection *next;
} connection_t;

connection_t *connections = NULL;

// Dummy geolocation lookup (replace with a real API/library if needed)
const char* geolocate_ip(struct in_addr ip) {
    // For demonstration, we simply return a static string.
    return "Unknown Location";
}

// Add or update connection in the tracking list
void track_connection(struct in_addr src_ip, struct in_addr dst_ip, uint16_t src_port, uint16_t dst_port, int protocol, const char *state) {
    connection_t *conn = connections;
    while(conn) {
        if(conn->src_ip.s_addr == src_ip.s_addr &&
           conn->dst_ip.s_addr == dst_ip.s_addr &&
           conn->src_port == src_port &&
           conn->dst_port == dst_port &&
           conn->protocol == protocol) {
            strncpy(conn->state, state, sizeof(conn->state)-1);
            return;
        }
        conn = conn->next;
    }
    // Add new connection if not found
    connection_t *new_conn = malloc(sizeof(connection_t));
    if(!new_conn) return;
    new_conn->src_ip = src_ip;
    new_conn->dst_ip = dst_ip;
    new_conn->src_port = src_port;
    new_conn->dst_port = dst_port;
    new_conn->protocol = protocol;
    strncpy(new_conn->state, state, sizeof(new_conn->state)-1);
    new_conn->next = connections;
    connections = new_conn;
}

// Print a connection’s details
void print_connection(connection_t *conn) {
    char src_ip_str[INET_ADDRSTRLEN], dst_ip_str[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &(conn->src_ip), src_ip_str, INET_ADDRSTRLEN);
    inet_ntop(AF_INET, &(conn->dst_ip), dst_ip_str, INET_ADDRSTRLEN);
    printf(COLOR_YELLOW "Connection: %s:%d -> %s:%d, Protocol: %s, State: %s\n" COLOR_RESET,
           src_ip_str, conn->src_port, dst_ip_str, conn->dst_port,
           (conn->protocol == IPPROTO_TCP) ? "TCP" : "UDP",
           conn->state);
}

// Alert system: triggers on suspicious SYN packets
void check_alerts(const struct ip *ip_hdr, const struct tcphdr *tcp_hdr) {
    if(tcp_hdr && (tcp_hdr->syn) && !(tcp_hdr->ack)) {
        printf(COLOR_RED "Alert: Suspicious SYN packet detected from %s\n" COLOR_RESET, inet_ntoa(ip_hdr->ip_src));
    }
}

// Packet processing callback for libpcap
void packet_handler(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
    (void)args; // suppress unused parameter warning

    stats.packet_count++;
    stats.byte_count += header->len;

    const struct ether_header *eth_hdr = (struct ether_header *)packet;
    if(ntohs(eth_hdr->ether_type) == ETHERTYPE_IP) {
        const struct ip *ip_hdr = (struct ip*)(packet + sizeof(struct ether_header));
        int ip_header_length = ip_hdr->ip_hl * 4;

        char src_ip[INET_ADDRSTRLEN], dst_ip[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &(ip_hdr->ip_src), src_ip, INET_ADDRSTRLEN);
        inet_ntop(AF_INET, &(ip_hdr->ip_dst), dst_ip, INET_ADDRSTRLEN);

        printf(COLOR_GREEN "Packet %lu: %s -> %s, Protocol: %d\n" COLOR_RESET,
               stats.packet_count, src_ip, dst_ip, ip_hdr->ip_p);
        printf("Geolocation for %s: %s\n", src_ip, geolocate_ip(ip_hdr->ip_src));

        // Process TCP packets
        if(ip_hdr->ip_p == IPPROTO_TCP) {
            stats.tcp_count++;
            const struct tcphdr *tcp_hdr = (struct tcphdr*)(packet + sizeof(struct ether_header) + ip_header_length);
            uint16_t src_port = ntohs(tcp_hdr->source);
            uint16_t dst_port = ntohs(tcp_hdr->dest);
            track_connection(ip_hdr->ip_src, ip_hdr->ip_dst, src_port, dst_port, IPPROTO_TCP, "ESTABLISHED");
            // Check for HTTP traffic (port 80)
            if(src_port == 80 || dst_port == 80) {
                stats.http_count++;
                printf(COLOR_BLUE "HTTP packet detected\n" COLOR_RESET);
                int tcp_header_length = tcp_hdr->doff * 4;
                const u_char *payload = packet + sizeof(struct ether_header) + ip_header_length + tcp_header_length;
                int payload_length = header->len - (sizeof(struct ether_header) + ip_header_length + tcp_header_length);
                if(payload_length > 0) {
                    printf("HTTP Data (first 50 bytes): %.50s\n", payload);
                }
            }
            check_alerts(ip_hdr, tcp_hdr);
        }
        // Process UDP packets
        else if(ip_hdr->ip_p == IPPROTO_UDP) {
            stats.udp_count++;
            const struct udphdr *udp_hdr = (struct udphdr*)(packet + sizeof(struct ether_header) + ip_header_length);
            uint16_t src_port = ntohs(udp_hdr->source);
            uint16_t dst_port = ntohs(udp_hdr->dest);
            track_connection(ip_hdr->ip_src, ip_hdr->ip_dst, src_port, dst_port, IPPROTO_UDP, "ACTIVE");
            // Check for DNS traffic (port 53)
            if(src_port == 53 || dst_port == 53) {
                stats.dns_count++;
                printf(COLOR_BLUE "DNS packet detected\n" COLOR_RESET);
                // Detailed DNS header parsing can be added here.
            }
        }
        // Additional protocol analysis (e.g., ICMP) can be added here.
    }
}

// Export traffic statistics to a CSV file
void export_csv(const char *filename) {
    FILE *fp = fopen(filename, "w");
    if(!fp) {
        fprintf(stderr, "Error opening CSV file for export.\n");
        return;
    }
    fprintf(fp, "Packets,Bytes,TCP,UDP,HTTP,DNS\n");
    fprintf(fp, "%lu,%lu,%lu,%lu,%lu,%lu\n", stats.packet_count, stats.byte_count, stats.tcp_count, stats.udp_count, stats.http_count, stats.dns_count);
    fclose(fp);
    printf("Exported statistics to CSV file: %s\n", filename);
}

// Print usage instructions
void print_usage(const char *prog_name) {
    printf("Usage: %s [-i interface] [-f filter] [-o output_file] [-m export_mode] [-t capture_time]\n", prog_name);
    printf("   -i: Network interface (default: first available)\n");
    printf("   -f: BPF filter expression (default: none)\n");
    printf("   -o: Output file for export (default: none)\n");
    printf("   -m: Export mode: 'pcap' or 'csv' (default: csv)\n");
    printf("   -t: Capture time in seconds (default: 60 seconds)\n");
}

int main(int argc, char **argv) {
    char *dev = NULL;
    char errbuf[PCAP_ERRBUF_SIZE];
    char *filter_exp = "";
    char *output_file = NULL;
    char *export_mode = "csv";
    int capture_time = 60;
    int opt;

    // Process command-line arguments
    while((opt = getopt(argc, argv, "i:f:o:m:t:h")) != -1) {
        switch(opt) {
            case 'i':
                dev = optarg;
                break;
            case 'f':
                filter_exp = optarg;
                break;
            case 'o':
                output_file = optarg;
                break;
            case 'm':
                export_mode = optarg;
                break;
            case 't':
                capture_time = atoi(optarg);
                break;
            case 'h':
            default:
                print_usage(argv[0]);
                exit(EXIT_SUCCESS);
        }
    }

    // Find default device if none specified
    if(dev == NULL) {
        dev = pcap_lookupdev(errbuf);
        if(dev == NULL) {
            fprintf(stderr, "Error finding default device: %s\n", errbuf);
            exit(EXIT_FAILURE);
        }
    }

    printf("Sir, capturing on interface: %s\n", dev);
    printf("Filter expression: %s\n", filter_exp);

    pcap_t *handle = pcap_open_live(dev, BUFSIZ, 1, 1000, errbuf);
    if(handle == NULL) {
        fprintf(stderr, "Could not open device %s: %s\n", dev, errbuf);
        exit(EXIT_FAILURE);
    }

    // Compile and apply the filter if provided
    if(strlen(filter_exp) > 0) {
        struct bpf_program fp;
        if(pcap_compile(handle, &fp, filter_exp, 0, PCAP_NETMASK_UNKNOWN) == -1) {
            fprintf(stderr, "Error compiling filter: %s\n", pcap_geterr(handle));
            exit(EXIT_FAILURE);
        }
        if(pcap_setfilter(handle, &fp) == -1) {
            fprintf(stderr, "Error setting filter: %s\n", pcap_geterr(handle));
            exit(EXIT_FAILURE);
        }
    }

    // Capture packets for the specified duration
    time_t start = time(NULL);
    while((time(NULL) - start) < capture_time) {
        pcap_dispatch(handle, 10, packet_handler, NULL);
    }

    // Export data if requested
    if(output_file) {
        if(strcmp(export_mode, "csv") == 0) {
            export_csv(output_file);
        } else if(strcmp(export_mode, "pcap") == 0) {
            // PCAP export functionality via pcap_dump could be implemented here.
            printf("PCAP export functionality not implemented in this snippet.\n");
        } else {
            fprintf(stderr, "Unknown export mode: %s\n", export_mode);
        }
    }

    pcap_close(handle);

    // Final statistics summary
    printf("Capture finished.\n");
    printf("Total Packets: %lu, Total Bytes: %lu\n", stats.packet_count, stats.byte_count);
    printf("TCP: %lu, UDP: %lu, HTTP: %lu, DNS: %lu\n", stats.tcp_count, stats.udp_count, stats.http_count, stats.dns_count);

    // Print tracked connections
    connection_t *conn = connections;
    while(conn) {
        print_connection(conn);
        conn = conn->next;
    }

    return 0;
}
