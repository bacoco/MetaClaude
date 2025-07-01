# Technical Writing Style Guide

This guide establishes writing standards for all technical documentation to ensure clarity, consistency, and professionalism across all content.

## Table of Contents

1. [Writing Principles](#writing-principles)
2. [Voice and Tone](#voice-and-tone)
3. [Grammar and Mechanics](#grammar-and-mechanics)
4. [Technical Terminology](#technical-terminology)
5. [Content Structure](#content-structure)
6. [Accessibility](#accessibility)
7. [Internationalization](#internationalization)
8. [Examples and Code](#examples-and-code)
9. [Common Mistakes](#common-mistakes)
10. [Quick Reference](#quick-reference)

---

## Writing Principles

### Clarity First
- Write for your reader, not yourself
- Use simple, direct language
- Avoid jargon unless necessary
- Define technical terms on first use

### Conciseness
- Eliminate unnecessary words
- Use active voice
- Get to the point quickly
- One idea per sentence

### Consistency
- Use the same terms throughout
- Follow established patterns
- Maintain uniform style
- Apply standards universally

### Accuracy
- Verify all technical information
- Test all code examples
- Update outdated content
- Cite sources when needed

---

## Voice and Tone

### Professional Yet Friendly
- **DO**: "You can configure the settings..."
- **DON'T**: "Hey there! Let's configure those settings!"

### Direct and Confident
- **DO**: "This feature improves performance."
- **DON'T**: "This feature might possibly improve performance."

### Helpful and Supportive
- **DO**: "If you encounter an error, check the log files."
- **DON'T**: "You probably made an error somewhere."

### Voice Guidelines

#### Active Voice (Preferred)
- ✅ "The system processes the request"
- ❌ "The request is processed by the system"

#### Second Person
- ✅ "You can install the package"
- ❌ "One can install the package"
- ❌ "The user can install the package"

#### Present Tense
- ✅ "The function returns a value"
- ❌ "The function will return a value"

---

## Grammar and Mechanics

### Capitalization

#### Title Case for Headings
- Main words capitalized
- Articles, prepositions under 4 letters lowercase
- Example: "Getting Started with the API"

#### Sentence Case for UI Elements
- Only first word and proper nouns capitalized
- Example: "Click the Save button"

### Punctuation

#### Lists
**Bulleted Lists:**
- Use for unordered items
- No periods for fragments
- Periods for complete sentences

**Numbered Lists:**
1. Use for sequential steps
2. Use for ordered items
3. Always use periods

#### Oxford Comma
Always use: "Python, JavaScript, and Ruby"

### Numbers

#### Spell Out
- Numbers one through nine
- Numbers starting sentences
- Approximations: "about a thousand"

#### Use Numerals
- Numbers 10 and above
- Technical measurements: "8 GB RAM"
- Version numbers: "version 2.0"

---

## Technical Terminology

### Standardized Terms

| Preferred | Avoid |
|-----------|-------|
| email | e-mail, Email |
| internet | Internet |
| URL | url, Url |
| API | api, Api |
| JavaScript | Javascript, JS |
| macOS | MacOS, Mac OS |
| sign in | log in, login |
| set up (verb) | setup |
| setup (noun) | set up |

### Acronyms and Abbreviations

#### First Use
- Spell out with acronym in parentheses
- Example: "Application Programming Interface (API)"

#### Common Exceptions (No Spelling Out)
- HTML, CSS, JSON, XML
- HTTP, HTTPS, URL
- FAQ, CEO, CTO

### Code Terms

#### Inline Code
- Use backticks: `function_name()`
- Variable names: `userCount`
- File names: `config.json`
- Commands: `npm install`

#### Code vs. Regular Text
- ✅ "Run `npm install` to install dependencies"
- ❌ "Run npm install to install dependencies"

---

## Content Structure

### Document Organization

#### Hierarchy
1. **Title**: Clear, descriptive, action-oriented
2. **Introduction**: Brief overview and purpose
3. **Prerequisites**: What users need before starting
4. **Main Content**: Logical progression
5. **Next Steps**: Where to go next

#### Headings
- Use descriptive headings
- Maintain logical hierarchy
- Limit to 3-4 levels
- Front-load keywords

### Paragraphs
- 3-5 sentences maximum
- One main idea per paragraph
- Topic sentence first
- Supporting details follow

### Lists
- Use for 3+ similar items
- Parallel construction
- Consistent punctuation
- Logical ordering

### Tables
- Use for comparative data
- Include headers
- Align columns appropriately
- Keep cells concise

---

## Accessibility

### Alternative Text
- Describe image content
- Convey image purpose
- Keep concise (125 characters)
- Don't repeat caption

### Heading Structure
- Use semantic headings
- Don't skip levels
- One H1 per page
- Descriptive text

### Link Text
- **DO**: "Read the [installation guide](link)"
- **DON'T**: "[Click here](link) for the guide"

### Color and Contrast
- Don't rely solely on color
- Ensure sufficient contrast
- Provide text alternatives
- Test with accessibility tools

---

## Internationalization

### Language Considerations

#### Avoid Idioms
- ❌ "It's a piece of cake"
- ✅ "It's easy to do"

#### Cultural Neutrality
- Use inclusive examples
- Avoid culture-specific references
- Consider global audience
- Use international formats

### Formatting

#### Dates
- ISO format preferred: 2024-01-15
- Or spell out: January 15, 2024

#### Times
- 24-hour format: 14:30
- Or include timezone: 2:30 PM EST

#### Numbers
- Decimal separator varies by locale
- Consider using spaces: 1 000 000

---

## Examples and Code

### Code Examples

#### Complete and Runnable
```python
# Good: Complete example
def calculate_total(items):
    """Calculate the total price of items."""
    total = 0
    for item in items:
        total += item.price
    return total

# Usage
items = [Item(price=10), Item(price=20)]
total = calculate_total(items)
print(f"Total: ${total}")
```

#### Commented
```javascript
// Configure the API client
const client = new APIClient({
  apiKey: process.env.API_KEY,  // Store keys securely
  timeout: 5000,                // 5 seconds
  retries: 3                    // Retry failed requests
});
```

### Command-Line Examples

#### Show Both Input and Output
```bash
$ npm install express
added 50 packages in 2.5s

$ node --version
v14.17.0
```

#### Use Consistent Prompts
- `$` for Unix/Linux/macOS
- `>` for Windows Command Prompt
- `PS>` for PowerShell

---

## Common Mistakes

### Words and Phrases to Avoid

| Avoid | Use Instead |
|-------|-------------|
| "Simply/Just" | Remove or be specific |
| "Obviously" | Remove or explain |
| "Should work" | "Works" or test it |
| "Users can" | "You can" |
| "Please note" | "Note" or remove |
| "In order to" | "To" |
| "Utilize" | "Use" |
| "Via" | "Through" or "Using" |

### Common Grammar Errors

#### Its vs. It's
- **Its**: Possessive - "Check its status"
- **It's**: Contraction - "It's running"

#### Affect vs. Effect
- **Affect**: Verb - "This will affect performance"
- **Effect**: Noun - "The effect on performance"

#### That vs. Which
- **That**: Restrictive - "Files that are large"
- **Which**: Non-restrictive - "Files, which are large,"

---

## Quick Reference

### Checklist for Every Document

#### Before Writing
- [ ] Identify target audience
- [ ] Define document purpose
- [ ] Outline main points
- [ ] Gather technical details

#### While Writing
- [ ] Use active voice
- [ ] Write in second person
- [ ] Define technical terms
- [ ] Include examples
- [ ] Add visuals where helpful

#### After Writing
- [ ] Check for accuracy
- [ ] Test all examples
- [ ] Verify links work
- [ ] Run spell check
- [ ] Read aloud for flow
- [ ] Get peer review

### Style Quick Guide

```yaml
voice: active
person: second
tense: present
tone: professional-friendly

headings:
  style: title-case
  levels: maximum-4

lists:
  style: parallel
  punctuation: consistent

code:
  inline: backticks
  blocks: fenced
  language: specified

examples:
  complete: true
  tested: true
  commented: true
```

### Writing Formulas

#### Instructions
1. Action verb
2. Direct object
3. Purpose (if needed)

Example: "Configure the database connection to enable data persistence."

#### Descriptions
1. What it is
2. What it does
3. When to use it

Example: "The cache service is a memory storage system that improves performance by storing frequently accessed data."

---

## Resources

### Style Guides
- [Microsoft Writing Style Guide](https://docs.microsoft.com/style-guide)
- [Google Developer Documentation Style Guide](https://developers.google.com/style)
- [Apple Style Guide](https://support.apple.com/guide/applestyleguide)

### Tools
- [Hemingway Editor](http://hemingwayapp.com/) - Readability
- [Grammarly](https://grammarly.com/) - Grammar checking
- [Vale](https://vale.sh/) - Style linting
- [alex](https://alexjs.com/) - Inclusive writing

### Further Reading
- "Technical Writing Process" by Kieran Morgan
- "Docs Like Code" by Anne Gentle
- "The Product is Docs" by Christopher Gales

---

**Last Updated:** January 2024  
**Version:** 1.0  
**Maintained by:** Technical Writing Team