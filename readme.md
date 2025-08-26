# A Tutor Helper

This small script aims to assist tutors in assessing an applicant's level and position during a rush's evaluation at a glance.

## Requirements

This script requires three environement variables:

```bash
TOSCRIPT=/path/to/your/directory // needed to store API tokens and request replies
API_UID=your_api_uid
API_SEC=your_api_secret
```

If you don't know how to get your 42API key and secret, please refer to [this documentation](https://api.intra.42.fr/apidoc/guides/getting_started).

You should export these variables in your shell configuration so that they are alway available.

I also recommend you create an alias on the script to simplify your workflow:

```bash
alias track='bash ~/path/to/scripts/track.sh'
```

## Usage

Simply execute the script by passing the desired login:

```bash
bash ~/path/to/scripts/track.sh <login>
```

The output will look like this:

```bash
Login     <login>
Level     <level>
Location  <cluster location>
Profile   https://profile.intra.42.fr/users/<login>

Working on
<PROJECT>     | Since: [DAYS ELAPSED]

Validated projects
<PROJECT> | Grade: <GRADE>/100 | On [DATE]
<PROJECT> | Grade: <GRADE>/100 | On [DATE]

Evaluation logs 
On <DATE> | Evaluated someone
On <DATE> | Booked evaluation
On <DATE> | Booked evaluation
```

## Troubleshooting

If things don't work, try:

- Checking that your API secret has not expired
- Checking that your path is properly configured
- That you have permission to create a directory wherever you put your scripts (the api-gen.sh needs to create a directory to store the API token).

Please make an issue if something looks like it's truly broken !

## Improvements

If you want to improve this script, feel free to fork and PR with an adequate description of your work !
