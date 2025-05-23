#!/usr/bin/env zsh

# --- 1. Argument check ---
if [ -z "$1" ]; then
    echo "ERROR: No SITE_URL provided."
    echo "Usage: $0 <SITE_URL>"
    exit 1
fi
SITE_URL_INPUT="$1"

if [[ ! "$SITE_URL_INPUT" =~ ^https?:// ]]; then
    SITE_URL_FOR_PARSING="https://$SITE_URL_INPUT"
    SITE_URL_FOR_WGET="https://$SITE_URL_INPUT"
else
    SITE_URL_FOR_PARSING="$SITE_URL_INPUT"
    SITE_URL_FOR_WGET="$SITE_URL_INPUT"
fi
SITE_URL_FOR_WGET=${SITE_URL_FOR_WGET%/}
echo "→ SITE_URL for Wget: \"$SITE_URL_FOR_WGET\""

# --- 2. Output directory setup ---
OUTPUT_DIR_NAME=$(echo "$SITE_URL_FOR_PARSING" | awk -F/ '{print $3}')
if [ -z "$OUTPUT_DIR_NAME" ]; then
    echo "ERROR: Could not extract a valid domain name from '$SITE_URL_INPUT'." >&2
    exit 1
fi
OUTPUT_DIR="./$OUTPUT_DIR_NAME"
echo "→ Creating output directory: \"$OUTPUT_DIR\""
if [ -d "$OUTPUT_DIR" ]; then
    echo "→ Output directory '$OUTPUT_DIR' already exists. Removing it before download."
    rm -rf "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to remove existing directory '$OUTPUT_DIR'." >&2
        exit 1
    fi
fi
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR_ABSOLUTE=$(cd "$OUTPUT_DIR" && pwd)
echo "→ Absolute path: \"$OUTPUT_DIR_ABSOLUTE\""

# --- 3. Asset domains ---
BASE_DOMAIN=$(echo "$SITE_URL_FOR_PARSING" | awk -F/ '{print $3}')
# YOU SHOULD VERIFY AND ADD ANY OTHER DOMAINS YOUR LIVE SITE USES FOR JS/CSS/FONTS
ADDITIONAL_ASSET_DOMAINS="cdn.prod.website-files.com,assets-global.website-files.com,assets.website-files.com,uploads-ssl.webflow.com,d3e54v103j8qbb.cloudfront.net,prod.spline.design,fonts.googleapis.com,fonts.gstatic.com,ajax.googleapis.com,static.cdn.com,*.jquery.com"
ALLOWED_DOMAINS="$BASE_DOMAIN,$ADDITIONAL_ASSET_DOMAINS"
POTENTIAL_SOURCE_DIRS=($(echo "$ALLOWED_DOMAINS" | tr ',' '\n'))
echo "→ Base domain: \"$BASE_DOMAIN\""
echo "→ Allowed domains for Wget: \"$ALLOWED_DOMAINS\""

# --- 4. Advanced config ---
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
WGET_LOG_FILE="$OUTPUT_DIR_ABSOLUTE/wget_download.log"
echo "→ Wget log file: \"$WGET_LOG_FILE\""

# --- 5. Download with Wget ---
cd "$OUTPUT_DIR_ABSOLUTE" || {
    echo "ERROR: Cannot cd to \"$OUTPUT_DIR_ABSOLUTE\"" >&2
    exit 1
}
echo "→ Starting download into \"$OUTPUT_DIR_ABSOLUTE\" ..."
wget \
    --recursive \
    --page-requisites \
    --adjust-extension \
    --convert-links \
    --restrict-file-names=windows \
    --domains "$ALLOWED_DOMAINS" \
    --no-parent \
    --level=inf \
    --timestamping \
    --user-agent="$USER_AGENT" \
    --span-hosts \
    --execute robots=off \
    --wait=0.5 --random-wait \
    -nv \
    -o "$WGET_LOG_FILE" \
    "$SITE_URL_FOR_WGET"
WGET_EXIT_CODE=$?
echo "→ Wget exit code: $WGET_EXIT_CODE"
if [ $WGET_EXIT_CODE -ne 0 ] && [ $WGET_EXIT_CODE -ne 8 ]; then
    echo "WARNING: Wget completed with code $WGET_EXIT_CODE (check \"$WGET_LOG_FILE\"). Some assets might be missing."
else
    echo "→ Download completed (or partially completed with recoverable errors)."
fi
echo "→ Current directory after wget: $(pwd)"

# --- Badge Removal Section Intentionally OMITTED ---

# --- 6. Restructure assets ---
echo "→ Restructuring assets..."
if [ -d "./$BASE_DOMAIN" ]; then
    echo "   • Moving primary site content from \"./$BASE_DOMAIN\"/ to root..."
    shopt -s dotglob
    mv -n "./$BASE_DOMAIN"/* . 2>/dev/null
    shopt -u dotglob
fi

echo "   • Creating target asset directories: css/, js/, images/, videos/, fonts/"
mkdir -p ./css ./js ./images ./videos ./fonts

asset_find_exclude_paths="-path ./css -o -path ./js -o -path ./images -o -path ./videos -o -path ./fonts"

echo "   • Moving .css files to ./css/"
find . -type d \( $asset_find_exclude_paths \) -prune -o -type f -name "*.css" -print -exec mv -n {} ./css/ \;
echo "   • Moving .js files to ./js/"
find . -type d \( $asset_find_exclude_paths \) -prune -o -type f -name "*.js" -print -exec mv -n {} ./js/ \;
echo "   • Moving image files to ./images/"
find . -type d \( $asset_find_exclude_paths \) -prune -o -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.svg" -o -iname "*.webp" -o -iname "*.ico" \) -print -exec mv -n {} ./images/ \;
echo "   • Moving video files to ./videos/"
find . -type d \( $asset_find_exclude_paths \) -prune -o -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.ogv" -o -iname "*.mov" \) -print -exec mv -n {} ./videos/ \;
echo "   • Moving font files to ./fonts/"
find . -type d \( $asset_find_exclude_paths \) -prune -o -type f \( -iname "*.woff" -o -iname "*.woff2" -o -iname "*.ttf" -o -iname "*.eot" -o -iname "*.otf" \) -print -exec mv -n {} ./fonts/ \;

echo "   • Cleaning up known source directories (e.g., from CDNs)..."
for src_dir in "${POTENTIAL_SOURCE_DIRS[@]}"; do
    if [ -d "./$src_dir" ]; then
        if [[ "$src_dir" != "css" && "$src_dir" != "js" && "$src_dir" != "images" && "$src_dir" != "videos" && "$src_dir" != "fonts" ]]; then
            if [ "$(ls -A "./$src_dir" 2>/dev/null)" ]; then
                echo "     - Attempting to remove non-empty \"./$src_dir\"..."
            else
                echo "     - Removing empty \"./$src_dir\"..."
            fi
            rm -rf "./$src_dir"
        fi
    fi
done
echo "   • Cleaning up remaining empty directories..."
find . -mindepth 1 -type d -empty -delete
echo "→ Asset restructure complete."

# --- 7. Update asset paths within CSS files ---
echo "→ Updating asset paths within CSS files..."
find ./css -name "*.css" -type f -print0 | while IFS= read -r -d '' css_file; do
    echo "   • Processing CSS file: \"$css_file\""
    perl -i.bak -p0777e '
        use File::Basename;
        use URI::Escape;

        sub get_asset_basename_css {
            my $path = shift;
            $path =~ s/^["'"'"']+//; $path =~ s/["'"'"']+$//;
            $path =~ s/[\?#].*$//;
            eval { $path = uri_unescape($path); };
            return basename($path);
        }

        s{url\(\s*(["'"'"']?)(?!data:)([^)"'"'"']*\.[a-zA-Z0-9\-_]+)\1\s*\)}{
            my $quote = $1;
            my $original_path = $2;
            my $full_match = $&;
            my $basename = get_asset_basename_css($original_path);

            if (length $basename > 0) {
                if ($basename =~ /\.(?:png|jpe?g|gif|svg|webp|ico)$/i && -e "../images/$basename") {
                    "url(" . $quote . "../images/" . $basename . $quote . ")";
                } elsif ($basename =~ /\.(?:woff2?|ttf|eot|otf|svg)$/i && -e "../fonts/$basename") {
                    "url(" . $quote . "../fonts/" . $basename . $quote . ")";
                } else {
                    # warn "CSS url() not rewritten (not found or unhandled type): $original_path in $ARGV\n";
                    $full_match;
                }
            } else {
                $full_match;
            }
        }gei;
    ' "$css_file" && rm -f "${css_file}.bak" || echo "     ✖ error updating paths in \"$css_file\"; backup at \"${css_file}.bak\""
done
echo "→ CSS path updating complete."

# --- 8. Update asset paths in HTML files ---
# THIS SECTION ONLY MODIFIES *.html FILES
echo "→ Updating asset paths in HTML files..."
find . -name "*.html" -type f -print0 | while IFS= read -r -d '' html_file; do
    echo "   • Processing HTML file: \"$html_file\""
    html_file_rel_path=${html_file#./}
    export CURRENT_HTML_FILE_PATH_FOR_PERL="$html_file_rel_path" # Pass to Perl

    perl -i.bak -p0777e '
        use File::Spec;
        use File::Basename;
        use URI::Escape;

        my $html_path = $ENV{"CURRENT_HTML_FILE_PATH_FOR_PERL"};
        my ($html_filename, $html_dirname_raw) = fileparse($html_path);
        my $html_dirname = ($html_dirname_raw eq "./" || $html_dirname_raw eq "" ) ? "." : $html_dirname_raw;
         $html_dirname =~ s/\/$//; # Remove trailing slash if present from fileparse

        sub calculate_relative_path_html {
            my ($target_dir) = @_;
            my $rel_path = File::Spec->abs2rel($target_dir, $html_dirname);
            $rel_path =~ s|/*$|/|;      # Ensure trailing slash
            $rel_path =~ s|^\./||;     # Remove leading ./
            return $rel_path;
        }

        sub get_asset_basename_html {
            my $path = shift;
            $path =~ s/[\?#].*$//; # Remove query string/fragment first
            # Basic URL decoding for common cases like %2F, %20 for the whole path before basename
            my $temp_path = $path;
            eval { $temp_path = uri_unescape($temp_path); };
            $temp_path = $path if $@; # if unescape fails, use original path for basename
            # Now get the basename from the (potentially) unescaped path
            my $basename = basename($temp_path);
            # Unescape the basename itself if it contains encoded characters (e.g., "file%20name.jpg")
            eval { $basename = uri_unescape($basename); };
            return $basename;
        }

        # Define absolute paths to target directories (relative to script CWD)
        my $css_dir_abs = "./css";
        my $js_dir_abs = "./js";
        my $img_dir_abs = "./images";
        my $vid_dir_abs = "./videos";
        my $font_dir_abs = "./fonts"; # Though fonts usually linked via CSS

        # Calculate relative path prefixes FROM the current HTML file TO the asset dirs
        my $css_rel_prefix = calculate_relative_path_html($css_dir_abs);
        my $js_rel_prefix = calculate_relative_path_html($js_dir_abs);
        my $img_rel_prefix = calculate_relative_path_html($img_dir_abs);
        my $vid_rel_prefix = calculate_relative_path_html($vid_dir_abs);
        my $font_rel_prefix = calculate_relative_path_html($font_dir_abs);

        # --- Meta og:image, twitter:image ---
        s{<meta[^>]*?(?:property|name)=["'"'"'](?:og:image|twitter:image)["'"'"'][^>]*?content=(["'"'"'])([^"'"'"']*?)\1}{
            my $quote = $1; my $original_path = $2; my $tag = $&;
            my $basename = get_asset_basename_html($original_path);
            if (length $basename > 0 && $basename =~ /\.(?:png|jpe?g|gif|svg|webp)$/i && -e "$img_dir_abs/$basename") {
                my $new_path = $img_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
            } else { $&; }
        }gei;

        # --- <link href="..."> ---
        s{<link[^>]*?href=(["'"'"'])(.*?)\1}{
            my $quote = $1; my $original_path = $2; my $tag = $&;
            my $basename = get_asset_basename_html($original_path);
            if (length $basename > 0 && $basename =~ /\.css$/i && -e "$css_dir_abs/$basename") {
                my $new_path = $css_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
            } elsif (length $basename > 0 && $basename =~ /\.(?:png|jpe?g|gif|svg|webp|ico)$/i && -e "$img_dir_abs/$basename") { # favicons
                my $new_path = $img_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
            } elsif (length $basename > 0 && $basename =~ /\.(?:woff2?|ttf|eot|otf)$/i && -e "$font_dir_abs/$basename") { # Unlikely but possible
                my $new_path = $font_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
            } else { $&; }
        }gei;

        # --- <script src="..."> ---
        # Captures <script ... src="..." ...>
        # Does NOT modify contents of .js files, only the src attribute in HTML.
        s{<script\s+((?:[^>](?!src=))*?)src=(["'"'"'])([^"'"'"'>]+?)\2((?:[^>](?!/>))*?)>}
         {
            my $pre_attrs_match = $1;
            my $quote_match = $2;
            my $original_path_match = $3;
            my $post_attrs_match = $4;

            my $basename = get_asset_basename_html($original_path_match);

            if (length $basename > 0 && $basename =~ /\.js$/i && -e "$js_dir_abs/$basename") {
                my $new_path = $js_rel_prefix . $basename;
                
                # Reconstruct the tag string for modification
                my $modified_tag_str = "<script " . $pre_attrs_match . "src=" . $quote_match . $new_path . $quote_match . $post_attrs_match . ">";
                
                # Remove integrity and crossorigin attributes
                $modified_tag_str =~ s/\s+integrity=["'"'"'][^"'"'"']*["'"'"']//gi;
                $modified_tag_str =~ s/\s+crossorigin(?:=["'"'"'][^"'"'"']*["'"'"'])?//gi;
                
                # Clean up potential double spaces from attribute removal
                $modified_tag_str =~ s/\s\s+/ /g;
                $modified_tag_str =~ s/\s>/>/g; # Remove space before closing > if it exists

                $modified_tag_str; # Return the modified opening tag
            } else {
                if ($original_path_match =~ /\.js/i) { # Only warn if it looked like a JS file
                    warn "HTML SCRIPT WARN: Path for JS file \"$original_path_match\" in HTML file \"$html_path\" was not rewritten (file not found in local ./js/ or basename issue).\n";
                }
                $&; # Return original matched opening tag if no rewrite
            }
        }geix; # x flag allows whitespace and comments in regex for readability

        # --- <img>, <source src="..."> for images, <a href="..."> to images ---
        s{<(img|source|a)\s[^>]*?(?:src|href)=(["'"'"'])([^"'"'"'>]+?)\2}{
            my ($tag_name, $quote, $original_path) = ($1, $2, $3); my $tag = $&;
            my $basename = get_asset_basename_html($original_path);
            if (length $basename > 0 && $basename =~ /\.(?:png|jpe?g|gif|svg|webp|ico)$/i && -e "$img_dir_abs/$basename") {
                 my $new_path = $img_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
             } else { $&; }
        }gei;

        # --- <img srcset="...">, <source srcset="..."> ---
        s{<(img|source)\s([^>]*?srcset=(["'"'"']))([^"'"'"']*)(\3[^>]*)}{
            my ($tag_name, $pre_attrs, $quote_char, $srcset_content, $post_attrs) = ($1, $2, $3, $4, $5);
            my @new_sources;
            foreach my $source_item (split /\s*,\s*/, $srcset_content) {
                 my ($url, $descriptor) = ($source_item =~ m/^(\S+)(?:\s+(\S+))?$/);
                 if (defined $url) {
                     my $basename = get_asset_basename_html($url);
                     if (length $basename > 0 && $basename =~ /\.(?:png|jpe?g|gif|svg|webp|ico)$/i && -e "$img_dir_abs/$basename") {
                         $url = $img_rel_prefix . $basename;
                     }
                 }
                 push @new_sources, (defined $descriptor ? "$url $descriptor" : $url);
            }
            "<$tag_name $pre_attrs" . join(", ", @new_sources) . "$post_attrs";
        }gei;

        # --- style="...background-image: url(...)..." ---
        s{(style=(["'"'"']))([^"'"'"']*?background(?:-image)?\s*:\s*url\(\s*(["'"'"']?)(?!data:)([^)"'"'"']*\.[a-zA-Z0-9\-_]+)\4\s*\)[^"'"'"']*?\2)}{
            my ($style_attr_start_token, $attr_quote_char, $style_content_before_url, $url_quote_char, $original_url_path) = ($1, $2, $3, $4, $5);
            my $full_match = $&; # Original full matched string "style=..."

            my $basename = get_asset_basename_html($original_url_path);
            my $new_url_target_path = "";

            if (length $basename > 0) {
                if ($basename =~ /\.(?:png|jpe?g|gif|svg|webp|ico)$/i && -e "$img_dir_abs/$basename") {
                    $new_url_target_path = $img_rel_prefix . $basename;
                } elsif ($basename =~ /\.(?:woff2?|ttf|eot|otf|svg)$/i && -e "$font_dir_abs/$basename") { # SVG can be font here too
                    $new_url_target_path = $font_rel_prefix . $basename;
                }
            }
            
            if ($new_url_target_path ne "") {
                # Reconstruct the style attribute carefully
                # Find the part of $style_content_before_url that is actually before url()
                $style_content_before_url =~ /^(.*?)background(?:-image)?\s*:\s*url\(\s*\Q$url_quote_char\E$/si;
                my $actual_prefix_in_style = $1 // ""; # Content before "background-image: url("

                # Extract suffix after the original path within url() up to the style attribute end
                my $original_style_content = $full_match;
                $original_style_content =~ s/^style=$attr_quote_char//i;
                $original_style_content =~ s/$attr_quote_char$//;
                
                my $suffix_in_style = "";
                if ($original_style_content =~ /\Q$original_url_path\E\Q$url_quote_char\E\s*\)(.*)/si) {
                    $suffix_in_style = $1;
                }

                "style=" . $attr_quote_char 
                       . $actual_prefix_in_style 
                       . "background-image: url(" . $url_quote_char . $new_url_target_path . $url_quote_char . ")"
                       . $suffix_in_style 
                       . $attr_quote_char;
            } else {
                $full_match; # Return original if no rewrite
            }
        }geix;

        # --- <video src/poster>, <source src>, <a href> for videos ---
         s{<(video|source|a)\s[^>]*?(src|href|poster)=(["'"'"'])([^"'"'"'>]+?)\3}{
            my ($tag_name, $attr_name, $quote, $original_path) = ($1, $2, $3, $4); my $tag = $&;
            my $basename = get_asset_basename_html($original_path);
            if (($attr_name eq "src" || $attr_name eq "href") && length $basename > 0 && $basename =~ /\.(?:mp4|webm|ogv|mov)$/i && -e "$vid_dir_abs/$basename") {
                 my $new_path = $vid_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
            } elsif ($attr_name eq "poster" && length $basename > 0 && $basename =~ /\.(?:png|jpe?g|webp)$/i && -e "$img_dir_abs/$basename") {
                 my $new_path = $img_rel_prefix . $basename; $tag =~ s/\Q$original_path\E/$new_path/; $tag;
            } else { $&; }
        }gei;

        # --- data-poster-url ---
         s{(data-poster-url=(["'"'"']))([^"'"'"']*)(\2)}{
             my ($attr_start, $quote, $original_path, $attr_end) = ($1, $2, $3, $4);
             my $basename = get_asset_basename_html($original_path);
             if (length $basename > 0 && $basename =~ /\.(?:png|jpe?g|webp)$/i && -e "$img_dir_abs/$basename") {
                 my $new_path = $img_rel_prefix . $basename; $attr_start . $new_path . $attr_end;
             } else { $&; }
         }gei;

        # --- data-video-urls ---
         s{(data-video-urls=(["'"'"']))([^"'"'"']*)(\2)}{
             my ($attr_start, $quote, $original_urls, $attr_end) = ($1, $2, $3, $4);
             my @new_video_urls;
             foreach my $url (split /\s*,\s*/, $original_urls) {
                 my $basename = get_asset_basename_html($url);
                 if (length $basename > 0 && $basename =~ /\.(?:mp4|webm|ogv|mov)$/i && -e "$vid_dir_abs/$basename") {
                     $url = $vid_rel_prefix . $basename;
                 }
                 push @new_video_urls, $url;
             }
             $attr_start . join(",", @new_video_urls) . $attr_end;
         }gei;

        # --- <video ... style="...background-image: url(POSTER_IMAGE)..."> ---
        # This is a more specific version of the general style url() replacer,
        # explicitly for <video> tags often used for poster images.
        s{(<video[^>]*style=(["'"'"'])) # $1: <video...style=", $2: quote
          ([^"'"'"']*?                 # $3: style content before url
           background(?:-image)?\s*:\s*url\(\s*(["'"'"']?) # $4: optional quote inside url
           (?!data:)                   # Negative lookahead for data:
           ([^)"'"'"']*\.(?:png|jpe?g|webp))  # $5: original_url_path (image extensions only)
           \4\s*\)                     # Closing quote and parenthesis
          ([^"'"'"']*?)                # $6: style content after url
          \2                           # Closing quote for style attribute
         }
         {
            my ($video_tag_start_style, $style_attr_quote, 
                $style_content_before_url, $url_internal_quote, 
                $original_image_path, $style_content_after_url) = ($1, $2, $3, $4, $5, $6);
            
            my $full_match = $&; # Keep original match for fallback

            my $basename = get_asset_basename_html($original_image_path);

            if (length $basename > 0 && -e "$img_dir_abs/$basename") { # Image must exist
                my $new_image_path = $img_rel_prefix . $basename;
                # Reconstruct the entire match with the new path
                $video_tag_start_style . 
                $style_content_before_url . 
                "background-image: url(" . $url_internal_quote . $new_image_path . $url_internal_quote . ")" .
                $style_content_after_url .
                $style_attr_quote;
            } else {
                $full_match; # No change
            }
        }geix; # x flag for readability

    ' "$html_file" && rm -f "${html_file}.bak" || echo "     ✖ error updating paths in \"$html_file\"; backup at \"${html_file}.bak\""
done

echo "→ Path updating complete."

# --- 9. Finished ---
echo "=== Script finished. Check \"$WGET_LOG_FILE\" for download errors. ==="
echo "=== Site downloaded to: \"$OUTPUT_DIR_ABSOLUTE\" ==="
