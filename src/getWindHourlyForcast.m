function [windHourlyForcast] = getWindHourlyForcast(windBuses)

windng = length(windBuses);

windHourly=[
127	92	212	153	21	281	231	50	83	47	81	187	155	44	273	307	28	40	51
64	90	153	229	8	174	125	16	72	37	48	152	123	82	283	256	11	28	74
72	71	261	336	3	242	105	1	46	25	37	107	89	75	191	238	10	23	48
53	66	191	198	2	332	242	1	109	18	28	81	73	84	205	231	6	15	23
26	63	92	93	8	291	360	1	193	12	15	66	49	109	267	215	18	18	38
13	42	84	79	23	259	351	8	178	9	14	56	70	101	320	168	19	23	33
27	46	93	107	29	222	255	30	135	6	13	53	46	33	262	130	11	43	22
91	90	164	150	19	106	233	32	98	14	39	47	42	7	187	69	10	83	14
119	90	206	107	8	40	254	27	82	31	53	65	43	6	161	58	28	131	17
99	100	177	59	5	105	376	29	96	21	33	92	87	19	196	122	55	139	32
106	168	162	65	5	143	271	20	195	24	23	140	119	40	265	213	34	113	36
212	149	145	42	9	175	375	7	201	58	80	196	193	74	296	289	16	94	37
279	104	166	26	7	228	403	4	138	131	215	190	158	92	453	367	7	106	49
280	83	214	59	11	257	367	4	185	141	274	249	214	95	465	404	5	156	71
239	97	243	145	13	248	408	4	196	138	278	252	269	89	482	447	10	192	80
261	64	165	88	13	103	419	4	155	136	283	267	275	77	513	493	109	251	80
277	163	104	41	11	284	398	6	173	141	288	267	284	86	539	523	137	252	107
235	220	107	40	7	285	420	20	249	146	289	288	287	84	557	513	140	261	131
211	252	194	189	3	346	426	16	257	147	284	289	285	95	560	480	135	259	143
257	253	366	362	2	505	506	9	274	146	278	288	289	92	533	496	85	234	145
276	263	449	438	12	550	544	18	290	142	245	288	287	80	540	520	121	232	146
282	271	474	489	30	550	538	56	293	136	231	287	286	62	566	548	134	218	147
255	253	492	445	40	544	528	76	292	131	227	288	288	87	578	563	129	122	146
178	248	382	339	76	525	510	63	284	140	247	287	287	129	573	552	128	153	147
];

windHourlyForcast = windHourly(:,1:windng);