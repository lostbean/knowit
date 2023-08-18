import cytoscape from "cytoscape"

export const Graph = {
    mounted() {
        var ctx = this.el;
        var cy = cytoscape({
            container: ctx,

            boxSelectionEnabled: false,

            style: [
                {
                    selector: 'node',
                    css: {
                        'content': 'data(id)',
                        'text-valign': 'center',
                        'text-halign': 'center'
                    }
                },
                {
                    selector: ':parent',
                    css: {
                        'text-valign': 'top',
                        'text-halign': 'center',
                    }
                },
                {
                    selector: 'edge',
                    css: {
                        'curve-style': 'bezier',
                        'target-arrow-shape': 'triangle'
                    }
                }
            ],

            // elements: {
            //     nodes: [
            //         { data: { id: 'a', parent: 'b' }, position: { x: 215, y: 85 } },
            //         { data: { id: 'b' } },
            //         { data: { id: 'c', parent: 'b' }, position: { x: 300, y: 85 } },
            //         { data: { id: 'd' }, position: { x: 215, y: 175 } },
            //         { data: { id: 'e' } },
            //         { data: { id: 'f', parent: 'e' }, position: { x: 300, y: 175 } }
            //     ],
            //     edges: [
            //         { data: { id: 'ad', source: 'a', target: 'd' } },
            //         { data: { id: 'eb', source: 'e', target: 'b' } }

            //     ]
            // },

            layout: {
                name: 'preset',
                padding: 5
            }
        });

        this.handleEvent("add_points", ({ points }) => {
            console.log(points);
            cy.add(points);
            cy.layout({ name: 'random', fit: true}).run();
            cy.fit();
        });

    }
}