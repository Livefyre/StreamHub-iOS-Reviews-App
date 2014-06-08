//
//  LFSBasicHTMLParser.m
//  CommentStream
//
//  Created by Eugene Scherba on 9/19/13.
//  Copyright (c) 2013 Livefyre. All rights reserved.
//

#import "LFSBasicHTMLParser.h"
#import <OHAttributedLabel/NSAttributedString+Attributes.h>

#if __has_feature(objc_arc)
#define MRC_AUTORELEASE(x) (x)
#else
#define MRC_AUTORELEASE(x) [(x) autorelease]
#endif

@implementation LFSBasicHTMLParser

+(NSDictionary*)tagMappings
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            
            // &
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                return MRC_AUTORELEASE([[NSAttributedString alloc] initWithString:@"&"]);
            }, @"&amp;",
            
            // <
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                return MRC_AUTORELEASE([[NSAttributedString alloc] initWithString:@"<"]);
            }, @"&lt;",
            
            // >
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                return MRC_AUTORELEASE([[NSAttributedString alloc] initWithString:@">"]);
            }, @"&gt;",
            
            // new line
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                return MRC_AUTORELEASE([[NSAttributedString alloc] initWithString:@"\n"]);
            }, @"<br/?>",
            
            // Display inner content of <p></p> and <iframe> with a new line at the end
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange innerRange = [match rangeAtIndex:2];
                // make paragraphs (in Core Text, the newline character ends a paragraph)
                NSMutableAttributedString *innerText = [[str attributedSubstringFromRange:innerRange] mutableCopy];
                [innerText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
                return MRC_AUTORELEASE(innerText);
            }, @"<(iframe|p)\\b[^>]*>(.*?)</\\1>",
            
            // Ignoring <span>, <em>, <strong>, <i>, <b>, and <u>
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange innerRange = [match rangeAtIndex:2];
                return MRC_AUTORELEASE([str attributedSubstringFromRange:innerRange]);
            }, @"<(span|b|strong|i|em|u)\\b[^>]*>(.*?)</\\1>",
            
            // Hyperlinks
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange hrefRange = [match rangeAtIndex:2];
                NSRange innerRange = [match rangeAtIndex:3];
                NSString* href = [str attributedSubstringFromRange:hrefRange].string;
                NSMutableAttributedString* innerText = [[str attributedSubstringFromRange:innerRange] mutableCopy];
                [innerText setLink:[NSURL URLWithString:href] range:NSMakeRange(0, innerRange.length)];
                return MRC_AUTORELEASE(innerText);
            }, @"<a\\s[^>]*\\bhref\\s*=\\s*(['\"])(.*?)\\1[^>]*>(.*?)</a>",
            
            /*
            // Bold, strong
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange innerRange = [match rangeAtIndex:2];
                NSMutableAttributedString* innerText = [[str attributedSubstringFromRange:innerRange] mutableCopy];
                [innerText setTextBold:YES range:NSMakeRange(0, innerRange.length)];
                return MRC_AUTORELEASE(innerText);
            }, @"<(b|strong)\\b[^>]*>(.*?)</\\1>",
            
            // Underlined (no semantic equivalent)
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange innerRange = [match rangeAtIndex:1];
                NSMutableAttributedString* innerText = [[str attributedSubstringFromRange:innerRange] mutableCopy];
                [innerText setTextIsUnderlined:YES range:NSMakeRange(0, innerRange.length)];
                return MRC_AUTORELEASE(innerText);
            }, @"<u>(.*?)</u>",
            
            // Italic, em
            ^NSAttributedString*(NSAttributedString* str, NSTextCheckingResult* match)
            {
                NSRange innerRange = [match rangeAtIndex:2];
                NSMutableAttributedString* innerText = [[str attributedSubstringFromRange:innerRange] mutableCopy];
                [innerText setTextItalics:YES range:NSMakeRange(0, innerRange.length)];
                return MRC_AUTORELEASE(innerText);
            }, @"<(i|em)\\b[^>]*>(.*?)</\\1>",
            */
            
            nil];
}


@end
