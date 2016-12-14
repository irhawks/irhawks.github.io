#!/usr/bin/env python
# Plot a list of numbers with pyplot
import sys
import re
import matplotlib.pyplot as plt
plt.plot([1,2,3,4])
plt.ylabel('some numbers')
plt.savefig('../img/'+re.sub('.py$','.pdf',sys.argv[0]))
