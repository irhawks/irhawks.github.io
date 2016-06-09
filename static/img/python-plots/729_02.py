#!/usr/bin/env python
import sys; import re
import matplotlib.pyplot as plt
plt.plot([1,2,3,4],[1,4,9,16],'ro')
plt.axis([0,6,0,20])
plt.savefig('../img/'+re.sub('.py$','.pdf',sys.argv[0]))
