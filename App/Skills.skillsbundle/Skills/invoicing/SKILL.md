---
name: invoicing
description: Bill a client in Skyway when the request is vague or missing details, such as no amount, the usual amount, the same as last time, a rate per hour or per visit instead of a total, only a first name, or several jobs at once. Also for asking what was billed recently. Not for changing seats, trips, or mileage.
---

# Invoicing

When the user gave a client, a service, and a total in dollars, use the Create Invoice tool
right away.

When anything is missing or vague, use the Get Recent Invoices tool first and fill in what you
can from it:

- **Client.** If the user gave only a first name and exactly one recent client has that first
  name, use that client's full name as it appears on the invoice. If several do, ask which one.
  If none do, use the name as the user said it.
- **Amount.** For "the usual", "same as last time", or no amount at all, use the amount of the
  most recent invoice for that client and service, and tell the user which invoice it came from,
  by number and date. If there's no earlier invoice to go on, ask for the amount. Never guess one.
- **Rate and quantity.** For a rate and a count, like 3 walks at $40 or 2 hours at $60 an hour,
  multiply them and tell the user the total and how you got it.
- **Service.** If the user didn't say what it's for and every recent invoice for that client is
  for the same service, use that service and say so. Otherwise ask.

For several jobs for the same client in one request, create one invoice per job, unless the user
asks for a single invoice. A single invoice lists the jobs in its service and uses their total.

Before creating, check the recent invoices for one with the same client, service, and amount
issued today. If there is one, tell the user and ask whether they really want a second one.

Create Invoice only bills in US dollars. If the user gives another currency, say so and ask for
the amount in dollars.

Create Invoice shows its own confirmation, so don't ask the user to confirm a second time.

## Don't

- Don't make up an amount, a client, or a service.
- Don't create an invoice when the user only asked what they billed recently. List the invoices
  instead.
