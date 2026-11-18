---
name: invoicing
description: Bill a client in Skyway when the request is vague or missing details, such as no amount, the usual amount, the same as last time, a rate per hour or per visit instead of a total, only a first name, an amount in a currency other than US dollars, or several jobs at once. Also for asking what was billed recently, who still owes money, recording that an invoice was sent or that a client paid, deleting or undoing an invoice, and follow-ups about invoices already listed or created. Not for logging money the user spent, which is an expense, and not for changing seats, trips, or mileage.
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

## Payments

When the user says a client paid, use the Mark Invoice Paid tool with that client's unpaid
invoice. If the client has more than one unpaid invoice and the user didn't say which, or gave an
amount that matches none of them, use the Get Recent Invoices tool and ask which one was paid.

For "who owes me" or "what's outstanding", use the Get Recent Invoices tool and list the sent
and overdue invoices, overdue first, with their totals. Drafts haven't been sent, so they aren't
owed yet; mention them separately only if there are any.

## Sending

When the user says they sent, emailed, or gave an invoice to a client, use the Record Invoice as Sent
tool with that client's draft. Skyway doesn't send invoices itself, so never say it sent one.

## Undo

When the user says "undo that", "cancel that invoice", or "I made a mistake" right after you
created an invoice, use the Delete Invoice tool with the invoice you just created. Don't call Get
Recent Invoices to find it. Delete Invoice asks the user to confirm, so don't ask a second time.

If they want to fix a detail instead, like the amount, delete the invoice and create a corrected
one, and tell them that's what you did.

## Follow-ups

After you've listed invoices or created, sent, or paid one, the user often goes on about the same
invoices, like "mark the second one paid", "I sent John's", or "when is that one due?". Use the
invoices you already have from that answer, matched by their position in the list, client, or
number. Don't call Get Recent Invoices again or ask which invoice they mean when it's clear.

Answer questions about those invoices, like due dates, totals, or what's overdue, from what you
already have.

After creating an invoice, you can tell the user to let you know once they've sent it, so Skyway
can remind them when it's due. Don't mark it sent until they say so.

## Don't

- Don't make up an amount, a client, or a service.
- Don't create an invoice when the user only asked what they billed recently. List the invoices
  instead.
- Don't mark an invoice paid unless the user said it was paid.
- Don't mark an invoice sent unless the user said they sent it.
- Don't delete an invoice unless the user asked to delete, cancel, or undo it.
